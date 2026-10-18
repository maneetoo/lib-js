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

[**Lib-JS**](https://github.com/maneetoo/lib-js/) is **fully based** on [**ECMAScript® 2027 Language Specification**](https://tc39.es/ecma262/) and [**Mozilla MDN Web Docs - JavaScript**](https://developer.mozilla.org/en-US/docs/Web/JavaScript) and writen on **pure** [**Luau**](https://luau.org/) and can be run by **any** Luau runtime *(ex. [Roblox](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use), [Lune](https://github.com/lune-org/lune), [Lute](https://github.com/luau-lang/lute))* - **NOT [LUA](https://www.lua.org/)**.

> [!WARNING]
> 
> ## Not Recommended
> This library is still under development and is **not recommended** for use in large-scale projects. Some methods have yet to be  implemented but are **planned** for the future, as is documentation on how to use the library.


## Previous art

Initially, [**Lib-JS**](https://github.com/maneetoo/lib-js/) was created to **interpret** [**JS**](https://ecma-international.org/publications-and-standards/standards/ecma-262/) methods for the purpose of porting [**Vue.js**](https://vuejs.org/) to [**Luau**](https://luau.org/). While it currently serves this specific function, the library **will be expanded** in the future with new methods and enhancements to existing ones.

## Installation
[**Wally**](https://wally.run/package/maneetoo/lib-js)
```toml
libjs = "maneetoo/libjs@1.0.0"
```

[**Pesde**](https://pesde.dev/packages/maneetoo/libjs)
```bash
pesde add wally#maneetoo/libjs
```
or
```toml
LibJS = { wally = "maneetoo/libjs", version = "^1.0.0" }
```

## Example of Use

```luau
const LibJS = require "@lib-js"
const Boolean, Error, Number, String, globalThis = 
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
```

## License

[**Lib-JS**](https://github.com/maneetoo/lib-js/) is licensed under [**MIT License**]()

Copyright © 2026 @maneetoo