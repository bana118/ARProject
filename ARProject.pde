import gab.opencv.*;
import processing.video.*;

final boolean MARKER_TRACKER_DEBUG = true;
final boolean BALL_DEBUG = false;

final boolean USE_SAMPLE_IMAGE = false;

// We've found that some Windows build-in cameras (e.g. Microsoft Surface)
// cannot work with processing.video.Capture.*.
// Instead we use DirectShow Library to launch these cameras.
final boolean USE_DIRECTSHOW = true;

// final double kMarkerSize = 0.036; // [m]
final double kMarkerSize = 0.024; // [m]

Capture cap;
DCapture dcap;
OpenCV opencv;

// Variables for Homework 6 (2020/6/10)
// **************************************************************
float fov = 45; // for camera capture

// Marker codes to draw snowmans
final int[] towardsList = {0x1228, 0x0690, 0x005a, 0x0272};
int badAppleNumber = (int)random(3); //0 ~ 2
// int towards = 0x1228; // the target marker that the ball flies towards
// int towardscnt = 0; // if ball reached, +1 to change the target

//final int[] towardsList = {0x005A, 0x0272};
//int towards = 0x005A;

final float GA = 9.80665;

PVector snowmanLookVector;
PVector ballPos;
float ballAngle = 45;
float ballspeed = 0;

final int ballTotalFrame = 30;
final float snowmanSize = 0.020;
int frameCnt = 0;

HashMap<Integer, PMatrix3D> markerPoseMap;

MarkerTracker markerTracker;
PImage img;

KeyState keyState;

void selectCamera()
{
  String[] cameras = Capture.list();

  if (cameras == null)
  {
    println("Failed to retrieve the list of available cameras, will try the default");
    cap = new Capture(this, 640, 480);
  }
  else if (cameras.length == 0)
  {
    println("There are no cameras available for capture.");
    exit();
  }
  else
  {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    //cap = new Capture(this, cameras[5]);

    // Or, the settings can be defined based on the text in the list
    cap = new Capture(this, 1280, 720, "USB2.0 HD UVC WebCam", 30);
  }
}

void settings()
{
  if (USE_SAMPLE_IMAGE)
  {
    // Here we introduced a new test image in Lecture 6 (20/05/27)
    size(1280, 720, P3D);
    opencv = new OpenCV(this, "./marker_test2.jpg");
    // size(1000, 730, P3D);
    // opencv = new OpenCV(this, "./marker_test.jpg");
  }
  else
  {
    if (USE_DIRECTSHOW)
    {
      dcap = new DCapture();
      size(dcap.width, dcap.height, P3D);
      opencv = new OpenCV(this, dcap.width, dcap.height);
    }
    else
    {
      selectCamera();
      size(cap.width, cap.height, P3D);
      opencv = new OpenCV(this, cap.width, cap.height);
    }
  }
}

Detection d;
void setup()
{
  background(0);
  smooth();
  // frameRate(10);

  markerTracker = new MarkerTracker(kMarkerSize);

  if (!USE_DIRECTSHOW)
    cap.start();

  // Added on Homework 6 (2020/6/10)
  // Align the camera coordinate system with the world coordinate system
  // (cf. drawSnowman.pde)
  PMatrix3D cameraMat = ((PGraphicsOpenGL)g).camera;

  cameraMat.reset();

  keyState = new KeyState();

  // Added on Homework 6 (2020/6/10)
  ballPos = new PVector();                           // ball position
  markerPoseMap = new HashMap<Integer, PMatrix3D>(); // hashmap (code, pose)

  d = new Detection(); //initial of Detection class
}

void draw()
{

  PMatrix3D cameraMat = null;
  ArrayList<Marker> markers = new ArrayList<Marker>();
  markerPoseMap.clear();

  if (!USE_SAMPLE_IMAGE)
  {
    if (USE_DIRECTSHOW)
    {
      img = dcap.updateImage();
      opencv.loadImage(img);
    }
    else
    {
      if (cap.width <= 0 || cap.height <= 0)
      {
        println("Incorrect capture data. continue");
        return;
      }
      opencv.loadImage(cap);
    }
  }
  ortho();
  pushMatrix();
  translate(-width / 2, -height / 2, -(height / 2) / tan(radians(fov)));
  markerTracker.findMarker(markers);
  popMatrix();

  // use perspective camera
  perspective(radians(fov), float(width) / float(height), 0.01, 1000.0);

  // setup light
  // (cf. drawSnowman.pde)
  ambientLight(180, 180, 180);
  directionalLight(180, 150, 120, 0, 1, 0);
  lights();

  //println("markersize"+markers.size());

  // for each marker, put (code, matrix) on hashmap
  for (int i = 0; i < markers.size(); i++)
  {
    Marker m = markers.get(i);
    markerPoseMap.put(m.code, m.pose);
  }

  DetectionRet d_ret = d.detect();
  println("bad apple marker:" + towardsList[badAppleNumber]);
  for (int i = 0; i < 4; i++)
  {
    if (i == 3)
    {
      // forth marker draw
      PMatrix3D pose_this = d_ret.pos[i];

      if (pose_this == null)
        continue;
      pushMatrix();
      // apply matrix (cf. drawSnowman.pde)
      applyMatrix(pose_this);
      drawModel("witch.obj", 0.02, -PI/2);
      popMatrix();
    }
    else
    {
      PMatrix3D pose_this = d_ret.pos[i];

      if (pose_this == null)
        continue;

      pushMatrix();
      // apply matrix (cf. drawSnowman.pde)
      applyMatrix(pose_this);
      //rotateX(angle);
      if (d_ret.min_flag == true && d_ret.min_num == i && badAppleNumber == i)
        drawModel("bad_apple.obj", 0.02, PI/2); //draw bad
      else
        drawModel("apple.obj", 0.02, PI/2); //draw ok
      popMatrix();
    }
  }
  d.save(); //need to be added at the bottom of the draw()
  noLights();
  keyState.getKeyEvent();
  System.gc();
}

void captureEvent(Capture c)
{
  PGraphics3D g;
  if (!USE_DIRECTSHOW && c.available())
    c.read();
}

float rotateToMarker(PMatrix3D thisMarker, PMatrix3D lookAtMarker, int markernumber)
{
  PVector relativeVector = new PVector();
  relativeVector.x = lookAtMarker.m03 - thisMarker.m03;
  relativeVector.y = lookAtMarker.m13 - thisMarker.m13;
  relativeVector.z = lookAtMarker.m23 - thisMarker.m23;
  float relativeLen = relativeVector.mag();

  relativeVector.normalize();

  float[] defaultLook = {1, 0, 0, 0};
  snowmanLookVector = new PVector();
  snowmanLookVector.x = thisMarker.m00 * defaultLook[0];
  snowmanLookVector.y = thisMarker.m10 * defaultLook[0];
  snowmanLookVector.z = thisMarker.m20 * defaultLook[0];

  snowmanLookVector.normalize();

  float angle = PVector.angleBetween(relativeVector, snowmanLookVector);
  if (relativeVector.x * snowmanLookVector.y - relativeVector.y * snowmanLookVector.x < 0)
    angle *= -1;

  return angle;
}
