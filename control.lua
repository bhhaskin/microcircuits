
require("scripts.processor")
require("scripts.models_lib")

-- BEGIN TESTS (removed from release builds)
if script.active_mods["factorio-test"] then
    require("__factorio-test__/init")({
        "tests/smoke_test",
        "tests/processor_lifecycle_test",
        "tests/packing_test",
        "tests/comm_display_test",
        "tests/signal_test",
        "tests/comm_signal_test",
    }, {
        load_luassert = true,
    })
end
-- END TESTS
