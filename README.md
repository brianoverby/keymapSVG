# Create-KeymapSVG

This is my take on a keymap svg create thingy. It's based on the great work by [callum-oakley/keymap](https://github.com/callum-oakley/keymap) and [caksoylar/keymap](https://github.com/caksoylar/keymap).    

I use PowerShell a lot more than python, so I converted it to PowerShell and simplified it a bit. The input file format is json. The json file contains information about the layout of the keyboard, the different layers and the keys.

## Get stated

Install PowerShell. If you are running Windows you probably already got a recent version of PowerShell. You can find [install guide for PowerShell on MacOS and linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell).

Create a json file for you keymap - see the sample layouts.

## Run the script

```
Create-KeymapSVG.ps1 -KeymapJsonFile <pathToJsonFile> -OutputSVGFile <pathToSVGOutputFile> [ -PrintLayerName ]
```

The param `-printLayerName` prints the name of the keyboard layer as heading (see sample outputs)
