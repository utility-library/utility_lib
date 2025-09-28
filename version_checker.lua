local version = '1.4.2'
local versionurl = "https://raw.githubusercontent.com/utility-library/utility_lib/master/version"

PerformHttpRequest(versionurl, function(error, _version, header)
    _version = _version:gsub("\n", "")

    if version ~= _version then
        print("^1----------------------| Attention |---------------------")
        print("            ^0New version available [^1".._version.."^0]")
        print("     ^5https://github.com/utility-library/utility_lib")
        print("^1----------------------| Attention |---------------------^0")
    else
        print([[
^5,ggg,         gg                                               
^5dP""Y8a        88    I8          ,dPYb,         I8              
^5Yb, `88        88    I8          IP'`Yb         I8              
^5 `"  88        88 88888888  gg   I8  8I  gg  88888888           
^5     88        88    I8     ""   I8  8'  ""     I8              
^5     88        88    I8     gg   I8 dP   gg     I8    gg     gg 
^5     88        88    I8     88   I8dP    88     I8    I8     8I 
^5     88        88   ,I8,    88   I8P     88    ,I8,   I8,   ,8I 
^5     Y8b,____,d88, ,d88b, _,88,_,d8b,_ _,88,_ ,d88b, ,d8b, ,d8I 
^5      "Y888888P"Y888P""Y888P""Y88P'"Y888P""Y888P""Y88P""Y88P"888
^5                                                           ,d8I'
     ^0All is updated, have a good day!^5                    ,dP'8I 
^5    --------------------------------------------        ,8"  8I 
^5                                                        I8   8I 
^5                                                        `8, ,8I 
^5                                                         `Y8P"  ^0]])
    end
end)
