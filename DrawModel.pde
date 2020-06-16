// load and show 3dmodel(obj file)
// this function reqiures mtl file and png file for texture
// obj, mtl and png files must be in data directory
void drawModel(String objFilePath, float size, float angleX)
{
  PShape model = loadShape(objFilePath);
  pushMatrix();
  model.scale(size);
  rotateX(angleX);
  shape(model);
  popMatrix();
}
