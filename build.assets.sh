cd Sources/Shaders
./compile.sh
cd ../..
rm -f assets.aether.zip
cd Assets
zip -r -0 ../assets.aether.zip *
cd ..

