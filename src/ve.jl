# implementation of the GPUCompiler interfaces for generating Aurora-SX VE code

## target

export VECompilerTarget

Base.@kwdef struct VECompilerTarget <: AbstractCompilerTarget
end

llvm_triple(::VECompilerTarget) = "ve-unknown-linux"

function llvm_machine(target::VECompilerTarget)
    triple = llvm_triple(target)
    t = Target(triple=triple)

    cpu = ""  # tuning option for specific CPU for this target
    feat = ""
    optlevel = LLVM.API.LLVMCodeGenLevelDefault
    reloc = LLVM.API.LLVMRelocPIC
    #tm = TargetMachine(t, triple, cpu, feat, optlevel, reloc)
    tm = TargetMachine(t, triple, cpu, feat; reloc)
    asm_verbosity!(tm, true)

    return tm
end

# TODO: encode debug build or not in the compiler job
#       https://github.com/JuliaGPU/CUDAnative.jl/issues/368
runtime_slug(job::CompilerJob{VECompilerTarget}) = "ve"

const ve_intrinsics = () # TODO: ("vprintf", "__assertfail", "malloc", "free")
isintrinsic(::CompilerJob{VECompilerTarget}, fn::String) = in(fn, gcn_intrinsics)

function process_entry!(job::CompilerJob{VECompilerTarget}, mod::LLVM.Module, entry::LLVM.Function)
    entry = invoke(process_entry!, Tuple{CompilerJob, LLVM.Module, LLVM.Function}, job, mod, entry)

    if job.source.kernel
        # calling convention
        callconv!(entry, LLVM.API.LLVMCCallConv)
    end

    entry
end


