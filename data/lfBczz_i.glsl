/* Playstation by @kishimisu
   
   A path-traced rendering of the Playstation logo using 4 light bounces
   
   Released in Japan in 1994, rendered using the same number of characters.
*/

void mainImage(out vec4 O, vec2 F) 
{
    O = texture(iChannel0, F/iResolution.xy);
}