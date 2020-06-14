// load and show 3dmodel(obj file)
// this function reqiures mtl file and png file for texture
// obj, mtl and png files must be in data directory
void drawModel(String objFilePath, float size){
    PShape model = loadShape(objFilePath);
    pushMatrix();
      model.scale(size);
      rotateX(PI/2);
      shape(model);
    popMatrix();
}
