param (
    [Parameter(Mandatory,Position=0)]
    [string]$KeymapJsonFile,
    [Parameter(Position=1)]
    [string]$OutputSVGFile,
    [Parameter(Position=3)]
    [switch]$PrintLayerName
 )


# Load file
$keeb = ""
if(Test-Path -Path $KeymapJsonFile -PathType Leaf) {
    $keeb = Get-Content -Encoding UTF8 $KeymapJsonFile | ConvertFrom-Json
}
else {
    Write-Error "File not found!"
    exit
}

## Configuration
#  keys
$key_w = 60
$key_h = 50
$line_spacing = 16

#  padding
$pad_inner_w = 2
$pad_inner_h = 2
$pad_outer_w = $key_w / 2
$pad_outer_h = $key_h / 2

# SVG style
$style = @"

svg {
    font-family: SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;
    font-size: 14px;
    font-kerning: normal;
    text-rendering: optimizeLegibility;
    background-color: #111111;
}
rect {
    fill: #333333;
}
text {
    fill: #cccccc;
    text-anchor: middle;
    dominant-baseline: middle;
}
rect.hold {
    fill: #D7ECFE;
}
text.hold {
    fill: #333333;
}
.layer {
    fill: #cccccc;
    text-anchor: start;
    dominant-baseline: hanging;
    font-weight: bold;
    font-size: 18px;
}

"@

 #   filter: drop-shadow(3px 3px 1px rgb(0 0 0 / 0.3));

$IsSplit = $keeb.layout.split
$NumRows = $keeb.layout.rows
$NumColumns = $keeb.layout.columns
$NumThumbs = 0
$thumb_offset = 0
$NumLayers = $(foreach ($PropName in $keeb.layers.PSObject.Properties.Name) { $PropName }).Count
if($keeb.layout.thumbs) { $NumThumbs = $keeb.layout.thumbs }
if($keeb.layout.thumb_offset) { $thumb_offset = $keeb.layout.thumb_offset }

# Calculated variables
$keyspace_w = $key_w + 2 * $pad_inner_w
$keyspace_h = $key_h + 2 * $pad_inner_h
$hand_w = 0
$hand_h = 0
$layer_w = 0
$layer_h = 0
$board_w = 0
$board_h = 0
$padding_offset = 0
$LayerNameLabel_h = 0
if ($PrintLayerName) { $LayerNameLabel_h = 18 }


if($IsSplit) {
    # For split keyboards

    if(($NumColumns + $thumb_offset - $NumThumbs) -lt 0){
        $padding_offset = -1 * ($NumColumns + $thumb_offset - $NumThumbs) * $keyspace_w
    }


    $hand_w = $NumColumns * $keyspace_w + $padding_offset
    $hand_h = $NumRows * $keyspace_h
    $layer_w = $hand_w * 2 + $pad_outer_w
 
 
    if($NumThumbs -gt 0){
        $hand_h += $keyspace_h
        if($thumb_offset -gt 0){
            $layer_w += 2 * $thumb_offset * $keyspace_w
        }
    }

    $layer_h = $hand_h
 
    $board_w = $layer_w + 2 * $pad_outer_w
    $board_h = $NumLayers * $layer_h + ($NumLayers + 1) * $pad_outer_h + $NumLayers * $LayerNameLabel_h
}
else {
    $layer_w = $NumColumns * $keyspace_w + $pad_outer_w
    $layer_h = $NumRows * $keyspace_h
    $board_w = $layer_w + $pad_outer_w
    $board_h = $NumLayers * $layer_h + ($NumLayers + 1) * $pad_outer_h + $NumLayers * $LayerNameLabel_h
}



## Functions

function print_key {
    param(
        $x, $y, $key, $width
    )
    $key_class_text = ""
    if($key -match "^(.+)::(.*)") {
        $key_class_text = ' class="{0}"' -f $Matches[1]
        $key = $Matches[2]
    }

    $key_width = ($width * $key_w) + 2 * ($width - 1) * $pad_inner_w
    '<rect x="{0}" y="{1}" width="{2}" height="{3}"{4} rx="5" ry="5" />' -f ($x+$pad_inner_w),($y+$pad_inner_h),$key_width,$key_h,$key_class_text + "`n"

    # Split words and print multiline legend
    if($null -eq $key) {
        $key = ""
    }
    $words = $key.Split()
    $y += ($keyspace_h - ($words.Length - 1) * $line_spacing) / 2

    foreach ($word in $words) {
        '<text x="{0}" y="{1}"{2}>{3}</text>' -f ($x + ($keyspace_w / 2) * $width),$y,$key_class_text,[System.Net.WebUtility]::HtmlEncode($word) + "`n"
        $y += $line_spacing
    }

}

function print_row {
    param (
        $x,$y,$row
    )
    $width = 0
    $prev_key = $null
    for ($k = 0 ; $k -le $row.Count ; $k++) {
        if ($k -gt 0 -and ($null -eq $prev_key -or $row[$($k)] -ne $prev_key -or $k -eq ($row.Count))) {
            print_key $x $y $prev_key $width
            $x += $width * $keyspace_w
            $width = 0
        }
        $prev_key = $row[$($k)]
        $width += 1
    }
}

function print_block {
    param (
        $x, $y, $block
    )
    
    foreach ($r in $block) {
        print_row $x $y $r
        $y += $keyspace_h
    }
}

function print_layer {
    param (
        $x,$y,$layer
    )

    if($IsSplit) {
        # Split keeb prints left and right
        $x_left_block = $x + $padding_offset
        $x_right_block = $x + $hand_w + $pad_outer_w
        if($thumb_offset -gt 0){
            $x_right_block += 2 * $thumb_offset * $keyspace_w
        }
        print_block $x_left_block $y $layer.left
        print_block $x_right_block $y $layer.right
        
        if($NumThumbs -gt 0){
            # If thumbs are defined, print left and right
            print_row $($x + ($NumColumns - $NumThumbs) * $keyspace_w + $thumb_offset * $keyspace_w + $padding_offset) $($y + $NumRows * $keyspace_h) $layer.thumbs.left
            print_row $($x_right_block + -1 * $thumb_offset * $keyspace_w) $($y + $NumRows * $keyspace_h) $layer.thumbs.right
        }
       
    }
    else {
        # Non-split - just print the layer
        print_block $x $y $layer.keys
    }
    "`n"
}

function print_board {
    param (
        $x, $y, $keymap
    )
    $x += $pad_outer_w

    foreach($l in $keymap.PSObject.Properties.Name) {
        $y += $pad_outer_h
        if($PrintLayerName) {
            '<text x="{0}" y="{1}" class="layer">{2}</text>' -f (($x + $pad_inner_w + $padding_offset) ,$y,[System.Net.WebUtility]::HtmlEncode($l))  + "`n"
            $y += $LayerNameLabel_h
        }
        print_layer $x $y $keymap.$($l)
        $y += $layer_h
    }
}

# Output
$output = '<svg width="{0}" height="{1}" viewBox="0 0 {0} {1}" xmlns="http://www.w3.org/2000/svg">' -f $board_w, $board_h  + "`n"
$output += '<style>{0}</style>' -f $style  + "`n"
$output += print_board 0 0 $keeb.layers
$output += "</svg>`n"
$output = $output -replace('([0-9]+),([0-9]+)','$1.$2') # Set-Culture does not work on PowerShell core - so this is a hack to use '.' as decimal separator

if($OutputSVGFile) {
    $output | Out-File -Encoding utf8 -FilePath $OutputSVGFile
}
else {
    $output 
}
