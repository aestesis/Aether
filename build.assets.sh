cd Sources/Shaders
./compile.sh
cd ../..
rm -f assets.aether.zip
cd Assets
# compression not supported yet
zip -r -9 ../assets.aether.zip *
cd ..

