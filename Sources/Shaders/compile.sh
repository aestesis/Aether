find . -type f -iname "*.vert" -print0 | while IFS= read -r -d $'\0' line; do
    glslangValidator -V -o "$line.spv" "$line"
done
find . -type f -iname "*.frag" -print0 | while IFS= read -r -d $'\0' line; do
    glslangValidator -V -o "$line.spv" "$line"
done
mv -f *.spv ../../Assets/Shaders

