Get the pre-compiled binaries here: https://github.com/robgraeber/Unretiner/releases

Forked from cbowns. Creates standard res images from retina size images in a simple drag-and-drop tool for Mac OS X. Modified to support specific naming conventions for Cocos2d and Unity (2d toolkit). 

---- 3 Versions/Branches ----

Master - Cocos2d Version:  
Downsizes `-ipadhd`, `@4x`, `-hd`, and `@2x`-named images to standard res versions.  
Example Input: `sprite-ipadhd.png`  
Example Output: `sprite-hd.png`, `sprite.png` 

Unity Branch - 2d Toolkit Version:  
Downsizes `-ipadhd`, `@4x`, `-hd`, and `@2x`-named images to standard res versions.  
Example Input: `sprite@4x.png`  
Example Output: `sprite@2x.png`, `sprite@1x.png`  

@4x Renamer - Renamer version:  
Doesn't downsize, instead appends `@4x` to the end of all images to format them.  
Example Input: `sprite.png`  
Example Output: `sprite@4x.png`   
  
![](http://i.imgur.com/PZfzHdN.png)
