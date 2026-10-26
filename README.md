<div align="center">

<img src=".github/assets/logo.svg">

## Lib-JS
Everything what you need to write code in Luau with JS built-in objects

[![Get On Wally](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/2214a2aca82cbdd386b946d759d3348705d7555e/Badges/Community/Package/link-wally.svg)](https://wally.run/package/maneetoo/lib-js)
[![Get On Pesde](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/2214a2aca82cbdd386b946d759d3348705d7555e/Badges/Community/Package/link-pesde.svg)](https://pesde.dev/packages/maneetoo/libjs)
[![GitHub Releases](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/2214a2aca82cbdd386b946d759d3348705d7555e/Badges/Community/GitHub/link-github-releases.svg)](https://github.com/maneetoo/lib-js/releases)
[![Roblox OSS Discord Server](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/2214a2aca82cbdd386b946d759d3348705d7555e/Badges/Community/Discord/link-discord-roblox-oss.svg)](https://discord.gg/vtUJdtUK2J)
[![Changelog](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/2214a2aca82cbdd386b946d759d3348705d7555e/Badges/Roblox-Styled/Original/link-changelog.svg)](https://github.com/maneetoo/lib-js/blob/main/CHANGELOG.md)
[![My Works](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/2214a2aca82cbdd386b946d759d3348705d7555e/Badges/Roblox-Styled/Original/link-my-works.svg)](https://github.com/maneetoo/)

</div>

[**Lib-JS**](https://github.com/maneetoo/lib-js/) is **fully based** on [**ECMAScript® 2027 Language Specification**](https://tc39.es/ecma262/) and [**Mozilla MDN Web Docs - JavaScript**](https://developer.mozilla.org/en-US/docs/Web/JavaScript) and written on **pure** [**Luau**](https://luau.org/) and can be run by **any** Luau runtime *(ex. [Roblox](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use), [Lune](https://github.com/lune-org/lune), [Lute](https://github.com/luau-lang/lute))* (**NOT [LUA](https://www.lua.org/)**). 

## Installation
[**Wally**](https://wally.run/package/maneetoo/lib-js)
```toml
libjs = "maneetoo/libjs@2.0.0"
```

[**Pesde**](https://pesde.dev/packages/maneetoo/libjs)
```bash
pesde add wally#maneetoo/libjs
```
or
```toml
LibJS = { wally = "maneetoo/libjs", version = "^2.0.0" }
```

## Example of Use

```luau
const LibJS = require "@lib-js" -- change to correct path to lib-js!
const Boolean, Error, Number, String, globalThis = -- export globals from lib-js (js built-in objects)
    LibJS.Boolean, LibJS.Error, LibJS.Number, LibJS.String, LibJS.globalThis

globalThis.multiplyNumber = function(number: any, multiplyBy: any, convertToString: any): number
    const convertToStringValue: boolean = Boolean(convertToString)
    const numberValue: number, multiplyByValue: number = 
        Number(number), Number(multiplyBy)

    const multipliedNumber: number = numberValue * multiplyByValue
    if convertToStringValue then
        return String(multipliedNumber)
    end
    return multipliedNumber
end

--...in other script...
print(globalThis.multiplyNumber("2", 5, true)) -- "10"
print(globalThis.multiplyNumber(6, 5)) -- 30
```

## License

[**Lib-JS**](https://github.com/maneetoo/lib-js/) is licensed under [**MIT License**](https://github.com/maneetoo/lib-js/blob/maneetoo-readme/LICENSE)

Copyright © 2026 @maneetoo
