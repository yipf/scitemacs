
LOCAL_DIR=string.match(debug.getinfo(1, "S").source , "^@(.*)/") -- 第二个参数 "S" 表示仅返回 source,short_src等字段， 其他还可以 "n", "f", "I", "L"等 返回不同的字段信息  

package.path=LOCAL_DIR.."/?.lua;"..package.path

require("core")

require("bayes/main")
require("tex/main")
-- extensions defined here
