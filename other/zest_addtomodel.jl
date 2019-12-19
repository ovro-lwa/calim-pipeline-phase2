module peel_restore

using CasaCore.Tables
using TTCal
using NPZ

function go(msname,sourcesjsonfile)
    ms = Table(msname)
    data = TTCal.read(ms, "CORRECTED_DATA")
    meta = Metadata(ms)
    sources = readsources(sourcesjsonfile)
    beam = ConstantBeam()

    TTCal.flag_short_baselines!(data, meta, 10)

    peeling_sources = [ZestingSource(source) for source in sources]
    calibrations = peel!(data, meta, beam, peeling_sources, peeliter=3, maxiter=30, tolerance=1e-4)

    # write out peeling solutions
    sourcenum = 1
    for calibration in calibrations
        TTCal.write_for_python("peelsoln_source$sourcenum.npz", calibration)
        sourcenum+=1
    end

    models = genvis(meta, beam, sources[1])
    corrupt!(models, meta, calibrations[1])
    for i = 2:size(sources)[1]
        model = genvis(meta, beam, sources[i])
        corrupt!(model, meta, calibrations[i])
        putsrc!(models, model)
    end

    TTCal.write(ms, "CORRECTED_DATA", data, apply_flags=false)
    TTCal.write(ms, "MODEL_DATA", models, apply_flags=false)
    unlock(ms)
end
peel_restore.go(ARGS[1],ARGS[2])
end
