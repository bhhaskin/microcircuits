local commons = require("scripts.commons")

test("processor prototypes are loaded", function()
    assert(prototypes.entity[commons.processor_name])
    assert(prototypes.entity[commons.processor_name_1x1])
end)
