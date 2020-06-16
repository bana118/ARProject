import gab.opencv.*;
import org.opencv.imgproc.Imgproc;

import org.opencv.core.Core;

import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.MatOfFloat;

import org.opencv.core.CvType;

import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.core.Rect;

public class DetectionRet{
    boolean min_flag;
    int min_num;//fail when it's -1,just check flag to use this or not
}




class Detection {


    Detection() {
     
     
    }

    DetectionRet detect() {


 
 

  int min_i=-1;
  float min_float=50f;
DetectionRet ret=new DetectionRet();
  PMatrix3D pose_fourth = markerPoseMap.get(towardsList[3]);
 for (int i = 0; i < 3; i++) {
    PMatrix3D pose_this = markerPoseMap.get(towardsList[i]);

    if (pose_this == null )
    {

      continue;

    }

  
  
    
      // apply matrix (cf. drawSnowman.pde)
      //rotateX(angle);

      // draw snowman
      
      if(pose_fourth!=null)
      {
PVector relativeVector = new PVector();

 relativeVector.x = pose_fourth.m03 - pose_this.m03;
          relativeVector.y =pose_fourth.m13 - pose_this.m13;
          relativeVector.z=pose_fourth.m23 - pose_this.m23;
  
    
float relativeLen = abs(relativeVector.mag());
println("marker distance"+relativeLen);

if(relativeLen<min_float)
{
min_float=relativeLen;
min_i=i;
}

      }



    }
    
ret.min_num=min_i;
ret.min_flag=false;
if(min_i!=-1&&min_float<(markerTracker.kMarkerSizeLength*1.6))
   {
     ret.min_flag=true;
   }



return ret;


}




}
