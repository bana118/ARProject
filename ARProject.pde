import gab.opencv.*;
import processing.video.*;

final boolean MARKER_TRACKER_DEBUG = false;
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
// int towards = 0x1228; // the target marker that the ball flies towards
// int towardscnt = 0; // if ball reached, +1 to change the target

//final int[] towardsList = {0x005A, 0x0272};
//int towards = 0x005A;

final float GA = 9.80665;
int score = 0;
int bad_apple = 0;
boolean game_init = true;
boolean game_init_flag = false;
boolean show_result=false;
boolean show_result_flag=false;
long t0 = System.currentTimeMillis();

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
  int score = 0;
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
  drawScore(score);

  if (game_init == true)
  { //Reset/Init the game here

    long t1 = System.currentTimeMillis();

    if (game_init_flag == false)
    {
      float rand = random(1);
      if (rand < 0.3333)
      {
        bad_apple = 0;
      }
      else if (rand > 0.6666)
      {
        bad_apple = 2;
      }
      else
      {
        bad_apple = 1;
      }
      //bad_apple=(int) random(1)*10/3;

      println(bad_apple);
      game_init_flag = true;
      t0 = System.currentTimeMillis();
    }
    long dt = t1 - t0;
    //println(dt);
    if (dt < 1000)
    {
      drawStart("Start");
    }
    if (dt > 1000 && dt < 2000)
    {
      drawStart("3");
    }
    if (dt > 2000 && dt < 3000)
    {
      drawStart("2");
    }
    if (dt > 3000 && dt < 4000)
    {
      drawStart("1");
    }
    if (dt > 4000 && dt < 5000)
    {
      drawStart("GO");
    }
    if (dt > 5000 && dt < 6000)
    {
      game_init_flag = false;
      game_init = false;
    }
  }
  // for each marker, put (code, matrix) on hashmap
  for (int i = 0; i < markers.size(); i++)
  {
    Marker m = markers.get(i);
    markerPoseMap.put(m.code, m.pose);
    //println(m.code);
  }

  popMatrix();

  // use perspective camera
  perspective(radians(fov), float(width) / float(height), 0.01, 1000.0);

  // setup light
  // (cf. drawSnowman.pde)
  ambientLight(180, 180, 180);
  directionalLight(180, 150, 120, 0, 1, 0);
  lights();

  DetectionRet d_ret = d.detect();

  for (int i = 0; i < 4; i++)
  {
    PMatrix3D pose_this = d_ret.pos[i];

    if (pose_this == null)
      continue;

    pushMatrix();

    // apply matrix (cf. drawSnowman.pde)
    applyMatrix(pose_this);
    //rotateX(angle);

    if (game_init == false)
    {
      // draw apple
      if (i == 3)
      {
        drawModel("witch.obj", 0.02, -PI / 2);
      }
      else
      {
        if (show_result == true && d_ret.min_num == i && d_ret.min_num == bad_apple)
        {
          //drawModel("bad_apple.obj", 0.02, PI / 2); //draw bad
          //DRAW BAD APPLE ANIMATION
          drawSnowman(snowmanSize,true);
        }
        else
        {
          //drawModel("apple.obj", 0.02, PI / 2); //draw ok
          drawSnowman(snowmanSize,false);
        }
      }
      
      if (show_result == false)
      {
        if (d_ret.min_flag == true)
        {
          println("min_flg:" + d_ret.min_flag);
          println("bad_apple:" + bad_apple);
          if (d_ret.min_num == bad_apple)
          {
            score += 1;
            //println("Restart1");
            
            show_result = true;
          }
          else
          {
            //println("Restart2");
            score -= 1;
            
            show_result = true;
          }
        }
      }
      if (show_result == true) //we show the bad apple 3 seconds before restarting the game
      {
        long t1 = System.currentTimeMillis();
        if (show_result_flag==false)
        {
          t0 = System.currentTimeMillis();
          show_result_flag=true;
        }
        long dt=t1-t0;
        if (dt>3000)
        {
          game_init=true;
          show_result_flag=false;
          show_result=false;
        }
      }
    }

    // noFill();
    // strokeWeight(3);
    // stroke(255, 0, 0);
    // line(0, 0, 0, 0.02, 0, 0); // draw x-axis
    // stroke(0, 255, 0);
    // line(0, 0, 0, 0, 0.02, 0); // draw y-axis
    // stroke(0, 0, 255);
    // line(0, 0, 0, 0, 0, 0.02); // draw z-axis
    popMatrix();
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
