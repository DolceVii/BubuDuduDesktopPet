# Bubu & Dudu - Windows 10/11 desktop companions. PowerShell 5.1 / WPF. Enhanced pair scenes and richer animation.
param([switch]$ChristmasDemo)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms
Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class PetWin {
 [StructLayout(LayoutKind.Sequential)] public struct R { public int L,T,Rgt,B; }
 public delegate bool CB(IntPtr h, IntPtr p);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB callback, IntPtr p);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h,int attr,out R r,int cb);
 public static List<R> Windows(int own) {
  var result=new List<R>();
  EnumWindows((h,p)=>{uint pid;GetWindowThreadProcessId(h,out pid);
   if(pid==(uint)own || !IsWindowVisible(h) || IsIconic(h) || GetWindowTextLength(h)==0)return true;
   R r;if(!GetWindowRect(h,out r))return true;
   R ext; try{if(DwmGetWindowAttribute(h,9,out ext,Marshal.SizeOf(typeof(R)))==0)r=ext;}catch{}
   if(r.Rgt-r.L>100 && r.B-r.T>70 && r.L>-30000 && r.T>-30000)result.Add(r);
   return true;
  },IntPtr.Zero);return result;
 }
}
'@
$script:area=[System.Windows.SystemParameters]::WorkArea
$script:random=[Random]::new()
$script:pets=@()
$script:platforms=@()
$script:paused=$false
$script:frame=0
$script:watch=[System.Diagnostics.Stopwatch]::StartNew()
$script:last=0.0
$script:pairScene=''
$script:pairStepUntil=0.0
$script:lastPairScene= -10.0
$script:separateSince=0.0
$script:lastComfort=0.0
$script:lastLoggedError=-10.0
$script:lastCryTriggered=-100.0
$script:lastFoodSmell=-100.0
$script:lastRescueStarted=-100.0
$script:lastHammerChase=-120.0
$script:sleepRequestName=''
$script:sleepRequestUntil=0.0
$script:lastSleepScene=-240.0
# Autonomous coexistence: recover separate time between pair activities.
$script:nextSocialAllowed=33.0
$script:soloUntil=0.0
$script:prevPairScene=''
$script:sleepCooldown=180.0
$script:lastPersonalityTick=0.0
$script:lastStory=-90.0
$script:storyOwner=''
$script:storyKind=''
$script:storyPhase=0
$script:travelDirection=1
$script:lastSoloStick=-70.0
$script:nextStory=13.0
$script:nextBubblePlan=0.0
$script:lastAIDecision=''
$script:startupGreetingPending=$true
$script:speechSeq=0
$script:speechOwnerName=''
$script:lastSpeakerName=''
# Μνήμη δραστηριοτήτων και καταστάσεων χωρίς σύνδεση στο internet.
$script:aiLastActivity=@{}
$script:aiRecent=[System.Collections.Generic.List[string]]::new()
$script:aiLastSocial=0.0
$script:aiSocialCount=0
$script:aiLastSelectionIndex=@{}
$script:aiLastTry=0.0
$script:aiLastRest=0.0
# Τοπική εμπειρική μάθηση: διαφορετικός πίνακας Q για κάθε αρκουδίτσα.
# Δεν υπάρχει νευρωνικό δίκτυο, δίκτυο ή αυτόματη δημιουργία νέων reactions.
$script:learnActions=@('stick','pc','photo','travel','hammer','scold','hug','dance','kiss','gift','flower','sleep','christmas')
# Χριστουγεννιάτικη σκηνή: ανεξάρτητα γραφικά δέντρου και φωτάκια WPF.
$script:christmasDemo=([bool]$ChristmasDemo)
$script:christmasDemoStarted=$false
$script:xmasTreeWindow=$null
$script:xmasTreeLights=@()
$script:xmasTreeSide=-1
$script:xmasBubuTargetX=0.0
$script:xmasLightsOn=$false
$script:xmasStarPlaced=$false
$script:xmasStartAt=0.0
$script:learnQ=@{Bubu=@{};Dudu=@{}}
$script:learnCount=@{Bubu=@{};Dudu=@{}}
$script:learnPending=$null
$script:learnCancelled=$false
$script:learnEpisodes=0
$script:learnAlpha=0.12
$script:learnGamma=0.72
$script:learnLastSave=0.0
$script:learnDirectory=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'BubuDuduDesktopPet'
$script:learnPath=Join-Path $script:learnDirectory 'learning-v1.json'

function Get-Xaml([string]$name) {
 $isPanda=$name -eq 'Bubu'
 $head=if($isPanda){'#FFFCF8'}else{'#D7A080'}
 $body=if($isPanda){'#FFFCF8'}else{'#D7A080'}
 $limb=if($isPanda){'#FFFCF8'}else{'#D7A080'}
 $footColor=if($isPanda){'#44302C'}else{'#D7A080'}
 $bowVisibility=if($isPanda){'Visible'}else{'Collapsed'}
 $ear=if($isPanda){'#51342E'}else{'#D7A080'}
 $face=if($isPanda){'#FFFCF8'}else{'#D7A080'}
 $patch=if($isPanda){'#FFFCF8'}else{'#D7A080'}
 $tummy=if($isPanda){'#FFFCF8'}else{'#D7A080'}
 $cheeks=if($isPanda){'#F7B6AC'}else{'#F8D38C'}
 $innerEar=if($isPanda){'#51342E'}else{'#6D4439'}
 $bubbleFill=if($isPanda){'#FFF2F8'}else{'#FFF4DC'}
 $bubbleBorder=if($isPanda){'#C28AAB'}else{'#C0A077'}
 $x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Width="154" Height="170" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
 ShowInTaskbar="False" Topmost="True" ResizeMode="NoResize" Title="PETNAME">
 <Canvas Width="154" Height="170" Background="Transparent">
   <Ellipse x:Name="Shadow" Width="66" Height="8" Fill="#26000000" Canvas.Left="37" Canvas.Top="149"/>
  <Canvas x:Name="Art" Width="140" Height="158" RenderTransformOrigin="0.5,0.60">
   <!-- Rounded, dark-outlined chibi limbs. Independent transforms still drive walking. -->

   <Canvas x:Name="FrontBody" Panel.ZIndex="2" Width="140" Height="158">
    <Path Data="M 48,94 C 39,95 34,108 35,120 C 36,133 49,141 69,142 C 89,142 103,136 105,123 C 106,109 101,96 90,94 Z" Fill="BODYS" Stroke="#65433E" StrokeThickness="2.7" StrokeLineJoin="Round"/>
    <Ellipse Width="38" Height="30" Fill="TUMMYS" Canvas.Left="52" Canvas.Top="102" Opacity="0.24"/>
   </Canvas>
   <Canvas x:Name="ProfileBody" Panel.ZIndex="2" Width="140" Height="158" Visibility="Collapsed">
    <Ellipse x:Name="TailSide" Width="15" Height="14" Fill="BODYS" Stroke="#65433E" StrokeThickness="2" Canvas.Left="42" Canvas.Top="119" RenderTransformOrigin="0.85,0.5"/>
    <Ellipse Width="10" Height="10" Fill="BODYS" Stroke="#65433E" StrokeThickness="1.9" Canvas.Left="48" Canvas.Top="112"/>
    <Path Data="M 56,97 C 47,101 44,114 47,126 C 51,138 67,144 84,142 C 96,140 103,132 104,122 C 105,112 100,102 92,98 C 83,94 67,93 56,97 Z" Fill="BODYS" Stroke="#65433E" StrokeThickness="2.7" StrokeLineJoin="Round"/>
    <Ellipse Width="17" Height="20" Fill="TUMMYS" Canvas.Left="75" Canvas.Top="108" Opacity="0.22"/>
   </Canvas>
   <Canvas x:Name="BackBody" Panel.ZIndex="2" Width="140" Height="158" Visibility="Collapsed">
    <Path Data="M 48,94 C 39,95 34,108 35,120 C 36,133 49,141 69,142 C 89,142 103,136 105,123 C 106,109 101,96 90,94 Z" Fill="BODYS" Stroke="#65433E" StrokeThickness="2.7" StrokeLineJoin="Round"/>
    <Ellipse x:Name="TailBack" Width="19" Height="17" Fill="BODYS" Stroke="#65433E" StrokeThickness="2.0" Canvas.Left="61" Canvas.Top="123" RenderTransformOrigin="0.5,0.3"/>
    <Path x:Name="BackBowMark" Data="M 58 103 Q 70 108 82 103" Stroke="#2E211F" StrokeThickness="3.1" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Fill="Transparent" Visibility="BOWVIS"/>
   </Canvas>
   <!-- Proper anatomy: arms attach at the shoulder area of the body, feet peek out only below the belly. -->
   <!-- Articulated biped: hip-knee-ankle. Torso occludes the hip joints. -->
   <Line x:Name="ThighLeftOutline" X1="61" Y1="127" X2="57" Y2="137" Stroke="#65433E" StrokeThickness="12.0" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="-2"/>
   <Line x:Name="ShinLeftOutline" X1="57" Y1="137" X2="62" Y2="144" Stroke="#65433E" StrokeThickness="10.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ThighLeft" X1="61" Y1="127" X2="57" Y2="137" Stroke="LIMBS" StrokeThickness="9.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="-2"/>
   <Line x:Name="ShinLeft" X1="57" Y1="137" X2="62" Y2="144" Stroke="LIMBS" StrokeThickness="8.0" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ThighRightOutline" X1="80" Y1="127" X2="85" Y2="137" Stroke="#65433E" StrokeThickness="12.0" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="-2"/>
   <Line x:Name="ShinRightOutline" X1="85" Y1="137" X2="82" Y2="144" Stroke="#65433E" StrokeThickness="10.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ThighRight" X1="80" Y1="127" X2="85" Y2="137" Stroke="LIMBS" StrokeThickness="9.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="-2"/>
   <Line x:Name="ShinRight" X1="85" Y1="137" X2="82" Y2="144" Stroke="LIMBS" StrokeThickness="8.0" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Ellipse x:Name="LegLeft" Width="16" Height="16" Fill="FOOTCOLOR" Stroke="#65433E" StrokeThickness="2.0" Canvas.Left="54" Canvas.Top="136" Panel.ZIndex="-2" RenderTransformOrigin="0.5,0.10"/>
   <Ellipse x:Name="LegRight" Width="16" Height="16" Fill="FOOTCOLOR" Stroke="#65433E" StrokeThickness="2.0" Canvas.Left="74" Canvas.Top="136" Panel.ZIndex="-2" RenderTransformOrigin="0.5,0.10"/>
   <!-- Kinematic arm rig: 2 articulated bones with shoulder/elbow/wrist joints.
        Shoulder origins are inside the torso; body occludes each upper root. -->
   <Line x:Name="ArmLeftUpperOutline" X1="45" Y1="111" X2="36" Y2="122" Stroke="#65433E" StrokeThickness="18" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ArmLeftLowerOutline" X1="36" Y1="122" X2="29" Y2="131" Stroke="#65433E" StrokeThickness="15.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ArmLeftUpper" X1="45" Y1="111" X2="36" Y2="122" Stroke="LIMBS" StrokeThickness="15" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ArmLeftLower" X1="36" Y1="122" X2="29" Y2="131" Stroke="LIMBS" StrokeThickness="12.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Rectangle x:Name="ArmLeftHand" Width="10" Height="8" RadiusX="4" RadiusY="4" Fill="LIMBS" Stroke="#65433E" StrokeThickness="1.4" Canvas.Left="23.5" Canvas.Top="126.0" Panel.ZIndex="1"/>
   <Line x:Name="ArmRightUpperOutline" X1="95" Y1="111" X2="104" Y2="122" Stroke="#65433E" StrokeThickness="18" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ArmRightLowerOutline" X1="104" Y1="122" X2="111" Y2="131" Stroke="#65433E" StrokeThickness="15.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ArmRightUpper" X1="95" Y1="111" X2="104" Y2="122" Stroke="LIMBS" StrokeThickness="15" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Line x:Name="ArmRightLower" X1="104" Y1="122" X2="111" Y2="131" Stroke="LIMBS" StrokeThickness="12.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Panel.ZIndex="1"/>
   <Rectangle x:Name="ArmRightHand" Width="10" Height="8" RadiusX="4" RadiusY="4" Fill="LIMBS" Stroke="#65433E" StrokeThickness="1.4" Canvas.Left="105.5" Canvas.Top="126.0" Panel.ZIndex="1"/>
   <Canvas x:Name="Blanket" Width="112" Height="52" Canvas.Left="14" Canvas.Top="104" Visibility="Collapsed" Panel.ZIndex="2">
    <Path Data="M 8,18 C 17,9 32,5 56,5 C 82,5 99,9 106,18 L 106,41 C 90,48 73,50 56,50 C 39,50 22,48 8,41 Z" Fill="#F7A9C0" Stroke="#9A677D" StrokeThickness="2.1"/>
    <Path Data="M 12,17 C 30,25 82,25 101,17" Stroke="#FFDCE7" StrokeThickness="3.0" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Opacity="0.75"/>
    <Path Data="M 21,34 Q 28,38 35,34 M 47,36 Q 54,40 61,36 M 74,34 Q 81,38 88,34" Stroke="#E989AB" StrokeThickness="2.0" StrokeStartLineCap="Round" Fill="Transparent" Opacity="0.55"/>
   </Canvas>
   <Canvas x:Name="HeadGroup" Panel.ZIndex="3" Width="140" Height="130" RenderTransformOrigin="0.5,0.73">
    <Canvas x:Name="FrontHeadView">
     <Ellipse x:Name="EarLeft" Width="26" Height="26" Fill="EARS" Stroke="#65433E" StrokeThickness="2.6" Canvas.Left="28" Canvas.Top="29" RenderTransformOrigin="0.65,0.8"/>
     <Ellipse x:Name="EarRight" Width="26" Height="26" Fill="EARS" Stroke="#65433E" StrokeThickness="2.6" Canvas.Left="88" Canvas.Top="29" RenderTransformOrigin="0.35,0.8"/>
     <Ellipse Width="12" Height="12" Fill="INNEREAR" Canvas.Left="35" Canvas.Top="36" Opacity="0.55"/>
     <Ellipse Width="12" Height="12" Fill="INNEREAR" Canvas.Left="95" Canvas.Top="36" Opacity="0.55"/>
     <!-- Broad, softly squared head is the signature Bubu/Dudu silhouette. -->
     <Path Data="M 71,37 C 43,36 22,51 21,74 L 21,92 C 21,112 40,119 70,120 C 101,120 120,111 120,91 L 120,74 C 119,51 99,37 71,37 Z" Fill="HEADS" Stroke="#65433E" StrokeThickness="2.8" StrokeLineJoin="Round"/>
     <Canvas x:Name="FrontFace" Width="140" Height="130">
      <Ellipse Width="25" Height="21" Fill="CHEEKS" Canvas.Left="28" Canvas.Top="88" Opacity="0.91"/>
      <Ellipse Width="25" Height="21" Fill="CHEEKS" Canvas.Left="89" Canvas.Top="88" Opacity="0.91"/>
      <Ellipse x:Name="Eye1" Width="10" Height="10" Fill="#3C2927" Canvas.Left="49" Canvas.Top="78"/>
      <Ellipse x:Name="Eye2" Width="10" Height="10" Fill="#3C2927" Canvas.Left="83" Canvas.Top="78"/>
      <Ellipse x:Name="Glint1" Width="2.5" Height="2.5" Fill="#FFFFFF" Canvas.Left="51" Canvas.Top="79" Opacity="0.75"/>
      <Ellipse x:Name="Glint2" Width="2.5" Height="2.5" Fill="#FFFFFF" Canvas.Left="85" Canvas.Top="79" Opacity="0.75"/>
      <!-- The small omega-shaped smile replaces the oversized muzzle/nose. -->
      <Path x:Name="Smile" Data="M 65 94 Q 65 100 70 98 Q 73 95 75 98 Q 80 100 80 94" Stroke="#50312D" StrokeThickness="2.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent"/>
      <Ellipse x:Name="OpenMouth" Width="8" Height="11" Fill="#874456" Canvas.Left="69" Canvas.Top="96" Visibility="Collapsed"/>
      <Path x:Name="SadMouth" Data="M 66 105 Q 73 96 80 105" Stroke="#50312D" StrokeThickness="2.2" StrokeStartLineCap="Round" Fill="Transparent" Visibility="Collapsed"/>
      <Ellipse x:Name="Tear1" Width="6" Height="12" Fill="#72C9F7" Canvas.Left="48" Canvas.Top="89" Visibility="Collapsed"/>
      <Ellipse x:Name="Tear2" Width="6" Height="12" Fill="#72C9F7" Canvas.Left="90" Canvas.Top="89" Visibility="Collapsed"/>
     </Canvas>
    </Canvas>
    <Canvas x:Name="ProfileHeadView" Visibility="Collapsed">
     <!-- Both ears stay visible, matching the supplied side-view photographs. -->
     <Ellipse Width="25" Height="24" Fill="EARS" Stroke="#65433E" StrokeThickness="2.5" Canvas.Left="40" Canvas.Top="35"/>
     <Ellipse Width="23" Height="23" Fill="EARS" Stroke="#65433E" StrokeThickness="2.5" Canvas.Left="84" Canvas.Top="33"/>
     <Ellipse Width="10" Height="10" Fill="INNEREAR" Canvas.Left="90" Canvas.Top="40" Opacity="0.55"/>
     <!-- Smooth rounded skull, NO triangular protruding snout. -->
     <Path Data="M 67,39 C 40,39 27,55 27,80 C 27,105 44,120 74,120 C 100,120 116,107 116,85 C 116,58 96,39 67,39 Z" Fill="HEADS" Stroke="#65433E" StrokeThickness="2.8" StrokeLineJoin="Round"/>
     <Ellipse Width="24" Height="22" Fill="CHEEKS" Canvas.Left="85" Canvas.Top="86" Opacity="0.94"/>
     <Ellipse x:Name="ProfileEye" Width="9" Height="10" Fill="#3C2927" Canvas.Left="91" Canvas.Top="73"/>
     <Ellipse x:Name="ProfileGlint" Width="2.5" Height="2.5" Fill="White" Canvas.Left="93" Canvas.Top="74" Opacity="0.82"/>
     <!-- Tiny curved mouth within the rounded silhouette. -->
     <Path x:Name="ProfileSmile" Data="M 105,94 Q 109,98 112,94" Stroke="#50312D" StrokeThickness="2.1" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Fill="Transparent"/>
     <Ellipse x:Name="ProfileMouth" Width="6" Height="9" Fill="#874456" Canvas.Left="106" Canvas.Top="95" Visibility="Collapsed"/>
    </Canvas>
    <Canvas x:Name="BackHeadView" Visibility="Collapsed">
     <!-- Real rear view: two ears, single continuous back of skull, no facial features. -->
     <Ellipse Width="26" Height="26" Fill="EARS" Stroke="#65433E" StrokeThickness="2.6" Canvas.Left="28" Canvas.Top="29"/>
     <Ellipse Width="26" Height="26" Fill="EARS" Stroke="#65433E" StrokeThickness="2.6" Canvas.Left="88" Canvas.Top="29"/>
     <Ellipse Width="12" Height="12" Fill="INNEREAR" Canvas.Left="35" Canvas.Top="36" Opacity="0.45"/>
     <Ellipse Width="12" Height="12" Fill="INNEREAR" Canvas.Left="95" Canvas.Top="36" Opacity="0.45"/>
     <Path Data="M 71,37 C 43,36 22,51 21,74 L 21,92 C 21,112 40,119 70,120 C 101,120 120,111 120,91 L 120,74 C 119,51 99,37 71,37 Z" Fill="HEADS" Stroke="#65433E" StrokeThickness="2.8" StrokeLineJoin="Round"/>
    </Canvas>
   <!-- Small dark bow tie fixed at Bubu's neck, on top of the body and under the chin. -->
   <Canvas x:Name="BubuBow" Width="28" Height="16" Canvas.Left="57" Canvas.Top="116" Panel.ZIndex="5" IsHitTestVisible="False" Visibility="BOWVIS">
    <Path Data="M 13 7 C 9 5 4 3 2 5 C 1 8 3 12 7 12 L 13 9 Z" Fill="#3E2A27" Stroke="#2E211F" StrokeThickness="1.0"/>
    <Path Data="M 15 7 C 19 5 24 3 26 5 C 27 8 25 12 21 12 L 15 9 Z" Fill="#3E2A27" Stroke="#2E211F" StrokeThickness="1.0"/>
    <Ellipse Width="5" Height="6" Fill="#2E211F" Canvas.Left="11.5" Canvas.Top="5.5"/>
   </Canvas>
   <Canvas x:Name="BubuBowSide" Width="14" Height="12" Canvas.Left="97" Canvas.Top="116" Panel.ZIndex="5" IsHitTestVisible="False" Visibility="Collapsed">
    <Path Data="M 2 7 C 3 4 7 2 12 4 C 11 8 8 10 5 10 Z" Fill="#3E2A27" Stroke="#2E211F" StrokeThickness="1.0"/>
    <Ellipse Width="3.5" Height="4.5" Fill="#2E211F" Canvas.Left="3.5" Canvas.Top="5"/>
   </Canvas>
    <!-- Ground play: seated character stirs a little earth with a stick. -->
    <Canvas x:Name="GroundPlay" Width="100" Height="35" Canvas.Left="20" Canvas.Top="120" Visibility="Collapsed" Panel.ZIndex="4" IsHitTestVisible="False">
     <Ellipse Width="50" Height="9" Fill="#AE8B63" Opacity="0.8" Canvas.Left="27" Canvas.Top="24"/>
     <Path Data="M 32,28 Q 45,21 55,27 M 53,28 Q 67,22 73,26" Stroke="#806043" StrokeThickness="1.6" Fill="Transparent"/>
     <Line x:Name="GroundStick" X1="54" Y1="24" X2="32" Y2="2" Stroke="#805B38" StrokeThickness="4" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
    </Canvas>
    <Canvas x:Name="MiniLaptop" Width="70" Height="58" Canvas.Left="76" Canvas.Top="95" Visibility="Collapsed" Panel.ZIndex="4" IsHitTestVisible="False">
     <Rectangle Width="54" Height="35" RadiusX="4" RadiusY="4" Canvas.Left="5" Canvas.Top="2" Fill="#647E9C" Stroke="#33485F" StrokeThickness="2"/>
     <Rectangle Width="44" Height="26" Canvas.Left="10" Canvas.Top="6" Fill="#B4DDEC" RadiusX="2" RadiusY="2"/>
     <Path Data="M 2,40 L 62,40 L 69,47 L 0,47 Z" Fill="#889AAD" Stroke="#33485F" StrokeThickness="1.5"/>
     <Path Data="M 18 43 L 52 43" Stroke="#4D6174" StrokeThickness="1.3"/>
    </Canvas>
    <Canvas x:Name="CameraProp" Width="48" Height="40" Canvas.Left="93" Canvas.Top="92" Visibility="Collapsed" Panel.ZIndex="4" IsHitTestVisible="False">
     <Rectangle Width="44" Height="27" Canvas.Left="1" Canvas.Top="9" RadiusX="6" RadiusY="6" Fill="#566879" Stroke="#303D4C" StrokeThickness="2"/>
     <Rectangle Width="13" Height="7" Canvas.Left="7" Canvas.Top="3" Fill="#566879" RadiusX="2" RadiusY="2"/>
     <Ellipse Width="24" Height="24" Canvas.Left="13" Canvas.Top="11" Fill="#BCD3E1" Stroke="#2C4154" StrokeThickness="3"/>
     <Ellipse Width="9" Height="9" Canvas.Left="21" Canvas.Top="18" Fill="#5B7897"/>
    </Canvas>
    <Canvas x:Name="ToyHammer" Width="65" Height="92" Canvas.Left="81" Canvas.Top="24" RenderTransformOrigin="0.43,0.88" Visibility="Collapsed" IsHitTestVisible="False">
     <!-- Large soft cartoon toy hammer, no collision with Dudu -->
     <Path Data="M 28,78 L 29,20" Stroke="#684335" StrokeThickness="12" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
     <Path Data="M 28,78 L 29,20" Stroke="#E7B780" StrokeThickness="7" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
     <Rectangle Width="54" Height="26" RadiusX="11" RadiusY="11" Fill="#FF89B2" Stroke="#793F5A" StrokeThickness="3" Canvas.Left="2" Canvas.Top="6"/>
     <Ellipse Width="12" Height="19" Fill="#FFC1D8" Canvas.Left="6" Canvas.Top="9"/>
     <Ellipse Width="7" Height="7" Fill="#FFF6FB" Canvas.Left="23" Canvas.Top="13"/>
    </Canvas>
   <Canvas x:Name="Flower" Width="45" Height="65" Canvas.Left="23" Canvas.Top="60" Visibility="Collapsed" Panel.ZIndex="4">
    <Path Data="M 21 61 Q 25 32 21 17" Stroke="#4D9E59" StrokeThickness="3" Fill="Transparent"/>
    <Path Data="M 21 48 Q 7 41 8 32 Q 23 34 21 48" Fill="#72BE78"/>
    <Path Data="M 22 39 Q 36 31 36 24 Q 23 25 22 39" Fill="#5AAF6B"/>
    <Ellipse Width="19" Height="18" Fill="#FF9EBA" Canvas.Left="10" Canvas.Top="4"/>
    <Ellipse Width="19" Height="18" Fill="#FF9EBA" Canvas.Left="2" Canvas.Top="14"/>
    <Ellipse Width="19" Height="18" Fill="#FF9EBA" Canvas.Left="20" Canvas.Top="14"/>
    <Ellipse Width="18" Height="18" Fill="#FF9EBA" Canvas.Left="10" Canvas.Top="23"/>
    <Ellipse Width="16" Height="16" Fill="#FFE17D" Canvas.Left="11" Canvas.Top="14"/>
   </Canvas>
   <Canvas x:Name="Candy" Width="33" Height="24" Canvas.Left="29" Canvas.Top="82" Visibility="Collapsed" Panel.ZIndex="4">
    <Path Data="M 1 12 L 10 4 L 10 20 Z" Fill="#F7B95D" Stroke="#D77F73" StrokeThickness="1"/>
    <Path Data="M 32 12 L 23 4 L 23 20 Z" Fill="#F7B95D" Stroke="#D77F73" StrokeThickness="1"/>
    <Ellipse Width="17" Height="19" Fill="#F778AC" Stroke="#D35288" StrokeThickness="1" Canvas.Left="8" Canvas.Top="2"/>
    <Ellipse Width="6" Height="5" Fill="#FFE1ED" Canvas.Left="12" Canvas.Top="5"/>
   </Canvas>
   <Ellipse x:Name="Cookie" Width="22" Height="22" Fill="#D8A45D" Stroke="#9D632F" StrokeThickness="2" Canvas.Left="21" Canvas.Top="89" Visibility="Collapsed" Panel.ZIndex="4"/>
   <Ellipse x:Name="Crumb1" Width="4" Height="4" Fill="#693C25" Canvas.Left="28" Canvas.Top="94" Visibility="Collapsed" Panel.ZIndex="4"/>
   <Ellipse x:Name="Crumb2" Width="4" Height="4" Fill="#693C25" Canvas.Left="35" Canvas.Top="103" Visibility="Collapsed" Panel.ZIndex="4"/>
   </Canvas>
   <!-- Η βαλίτσα είναι αδελφό στοιχείο του κεφαλιού, όχι παιδί του HeadGroup. -->
    <Canvas x:Name="SuitcaseProp" Width="43" Height="55" Canvas.Left="96" Canvas.Top="100" Visibility="Collapsed" Panel.ZIndex="4" IsHitTestVisible="False">
     <Path Data="M 15,11 L 15,4 Q 15,1 19,1 L 25,1 Q 29,1 29,4 L 29,11" Fill="Transparent" Stroke="#6B4A42" StrokeThickness="4"/>
     <Rectangle Width="39" Height="37" Canvas.Left="2" Canvas.Top="11" RadiusX="7" RadiusY="7" Fill="#F9AB92" Stroke="#935A59" StrokeThickness="2"/>
     <Path Data="M 13 13 L 13 46 M 30 13 L 30 46" Stroke="#D77C76" StrokeThickness="3"/>
     <Ellipse Width="6" Height="6" Canvas.Left="8" Canvas.Top="46" Fill="#51494A"/>
     <Ellipse Width="6" Height="6" Canvas.Left="30" Canvas.Top="46" Fill="#51494A"/>
    </Canvas>

   <!-- Χριστουγεννιάτικα λαμπάκια, σε τέσσερις ξεχωριστές σπείρες. -->
   <!-- Προβάλλονται τμηματικά για να φαίνεται ο Dudu να μπερδεύεται σταδιακά. -->
   <Canvas x:Name="XmasWrap1" Width="140" Height="158" Panel.ZIndex="7" Visibility="Collapsed" IsHitTestVisible="False">
    <Path Data="M 17,108 Q 32,92 68,116 Q 102,134 124,106" Stroke="#477455" StrokeThickness="4.5" StrokeStartLineCap="Round" Fill="Transparent"/>
    <Ellipse Width="17" Height="17" Fill="#58BFFF" Opacity="0.25" Canvas.Left="17" Canvas.Top="99"/>
    <Ellipse x:Name="XmasBulb01" Width="8" Height="9" Fill="#58BFFF" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="21" Canvas.Top="103"/>
    <Ellipse Width="17" Height="17" Fill="#FFE66E" Opacity="0.25" Canvas.Left="61" Canvas.Top="107"/>
    <Ellipse x:Name="XmasBulb02" Width="8" Height="9" Fill="#FFE66E" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="65" Canvas.Top="111"/>
    <Ellipse Width="17" Height="17" Fill="#FF82B5" Opacity="0.25" Canvas.Left="110" Canvas.Top="100"/>
    <Ellipse x:Name="XmasBulb03" Width="8" Height="9" Fill="#FF82B5" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="114" Canvas.Top="104"/>
   </Canvas>
   <Canvas x:Name="XmasWrap2" Width="140" Height="158" Panel.ZIndex="7" Visibility="Collapsed" IsHitTestVisible="False">
    <Path Data="M 119,117 C 98,143 52,139 24,117" Stroke="#497459" StrokeThickness="4.5" StrokeStartLineCap="Round" Fill="Transparent"/>
    <Ellipse Width="17" Height="17" Fill="#9BE76C" Opacity="0.25" Canvas.Left="96" Canvas.Top="125"/>
    <Ellipse x:Name="XmasBulb04" Width="8" Height="9" Fill="#9BE76C" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="100" Canvas.Top="129"/>
    <Ellipse Width="17" Height="17" Fill="#FF8B75" Opacity="0.25" Canvas.Left="48" Canvas.Top="127"/>
    <Ellipse x:Name="XmasBulb05" Width="8" Height="9" Fill="#FF8B75" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="52" Canvas.Top="131"/>
    <Ellipse Width="17" Height="17" Fill="#FFE66E" Opacity="0.25" Canvas.Left="20" Canvas.Top="112"/>
    <Ellipse x:Name="XmasBulb06" Width="8" Height="9" Fill="#FFE66E" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="24" Canvas.Top="116"/>
   </Canvas>
   <Canvas x:Name="XmasWrap3" Width="140" Height="158" Panel.ZIndex="7" Visibility="Collapsed" IsHitTestVisible="False">
    <Path Data="M 17,120 C 28,150 100,151 120,126" Stroke="#467253" StrokeThickness="4.5" StrokeStartLineCap="Round" Fill="Transparent"/>
    <Ellipse Width="17" Height="17" Fill="#EA8BFF" Opacity="0.25" Canvas.Left="30" Canvas.Top="128"/>
    <Ellipse x:Name="XmasBulb07" Width="8" Height="9" Fill="#EA8BFF" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="34" Canvas.Top="132"/>
    <Ellipse Width="17" Height="17" Fill="#59D4F7" Opacity="0.25" Canvas.Left="66" Canvas.Top="139"/>
    <Ellipse x:Name="XmasBulb08" Width="8" Height="9" Fill="#59D4F7" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="70" Canvas.Top="143"/>
    <Ellipse Width="17" Height="17" Fill="#FFE66E" Opacity="0.25" Canvas.Left="106" Canvas.Top="123"/>
    <Ellipse x:Name="XmasBulb09" Width="8" Height="9" Fill="#FFE66E" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="110" Canvas.Top="127"/>
   </Canvas>
   <Canvas x:Name="XmasWrap4" Width="140" Height="158" Panel.ZIndex="7" Visibility="Collapsed" IsHitTestVisible="False">
    <Path Data="M 34,93 C 8,72 11,126 37,142 Q 71,160 110,137 C 135,123 121,97 107,90" Stroke="#497459" StrokeThickness="4" StrokeStartLineCap="Round" Fill="Transparent"/>
    <Ellipse Width="17" Height="17" Fill="#FF7D8D" Opacity="0.25" Canvas.Left="11" Canvas.Top="106"/>
    <Ellipse x:Name="XmasBulb10" Width="8" Height="9" Fill="#FF7D8D" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="15" Canvas.Top="110"/>
    <Ellipse Width="17" Height="17" Fill="#94EC77" Opacity="0.25" Canvas.Left="46" Canvas.Top="142"/>
    <Ellipse x:Name="XmasBulb11" Width="8" Height="9" Fill="#94EC77" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="50" Canvas.Top="146"/>
    <Ellipse Width="17" Height="17" Fill="#FFE66E" Opacity="0.25" Canvas.Left="110" Canvas.Top="101"/>
    <Ellipse x:Name="XmasBulb12" Width="8" Height="9" Fill="#FFE66E" Stroke="#FFFFFF" StrokeThickness="1" Canvas.Left="114" Canvas.Top="105"/>
   </Canvas>
   <!-- Ο Dudu γίνεται κατά λάθος «κορυφή» του δέντρου. -->
   <Canvas x:Name="XmasHeadStar" Width="60" Height="53" Canvas.Left="40" Canvas.Top="4" Panel.ZIndex="10" Visibility="Collapsed" IsHitTestVisible="False">
    <Path Data="M 30,2 L 38,18 L 57,20 L 43,32 L 48,50 L 30,40 L 12,50 L 17,32 L 3,20 L 22,18 Z" Fill="#FFD65E" Stroke="#C68C28" StrokeThickness="2.8" StrokeLineJoin="Round"/>
    <Path Data="M 30,8 L 34,21 L 47,23 L 38,31 L 41,42 L 30,35 L 19,42 L 23,31 L 13,23 L 26,21 Z" Fill="#FFF6B8" Opacity="0.70"/>
   </Canvas>
   <!-- Αστέρι στο χέρι της Bubu προτού το βάλει στον Dudu. -->
   <Canvas x:Name="XmasHeldStar" Width="33" Height="33" Visibility="Collapsed" Panel.ZIndex="9" IsHitTestVisible="False">
    <Path Data="M 17,1 L 21,11 L 32,12 L 24,19 L 27,31 L 17,25 L 6,31 L 9,19 L 1,12 L 12,11 Z" Fill="#FFD65E" Stroke="#C68C28" StrokeThickness="1.7" StrokeLineJoin="Round"/>
   </Canvas>
   <!-- Σκηνικό πρίζας/φις, στην εξωτερική πλευρά της Bubu. -->
   <Canvas x:Name="XmasOutlet" Width="43" Height="45" Canvas.Left="-7" Canvas.Top="101" Panel.ZIndex="8" Visibility="Collapsed" IsHitTestVisible="False">
    <Rectangle Width="39" Height="38" Canvas.Left="2" Canvas.Top="3" RadiusX="7" RadiusY="7" Fill="#FFF7EC" Stroke="#9E8075" StrokeThickness="2"/>
    <Ellipse Width="4" Height="7" Fill="#8C7771" Canvas.Left="14" Canvas.Top="16"/>
    <Ellipse Width="4" Height="7" Fill="#8C7771" Canvas.Left="25" Canvas.Top="16"/>
   </Canvas>
   <Canvas x:Name="XmasPlug" Width="46" Height="51" Canvas.Left="3" Canvas.Top="111" Panel.ZIndex="9" Visibility="Collapsed" IsHitTestVisible="False">
    <Path Data="M 10,17 Q 1,32 10,49" Stroke="#447054" StrokeThickness="3.6" Fill="Transparent"/>
    <Rectangle Width="19" Height="13" Canvas.Left="6" Canvas.Top="3" RadiusX="3" RadiusY="3" Fill="#68A078" Stroke="#37644C" StrokeThickness="1.7"/>
    <Line X1="25" Y1="6" X2="31" Y2="6" Stroke="#B0A18E" StrokeThickness="2.5"/>
    <Line X1="25" Y1="12" X2="31" Y2="12" Stroke="#B0A18E" StrokeThickness="2.5"/>
   </Canvas>
   <Ellipse x:Name="Sweat" Width="8" Height="13" Fill="#74C6EC" Canvas.Left="112" Canvas.Top="50" Visibility="Collapsed"/>
   <TextBlock x:Name="Sparkle" Text="✦" FontSize="19" Foreground="#F0B344" Canvas.Left="110" Canvas.Top="33" Visibility="Collapsed"/>
   <TextBlock x:Name="Heart" Text="♥" FontSize="30" Foreground="#FF608C" Canvas.Left="56" Canvas.Top="9" Visibility="Collapsed"/>
   <TextBlock x:Name="KissHeart" Text="♥" FontSize="16" Foreground="#FB5E91" Canvas.Left="110" Canvas.Top="75" Panel.ZIndex="5" Visibility="Collapsed" IsHitTestVisible="False"/>
   <TextBlock x:Name="MusicNote" Text="♫" FontSize="27" FontWeight="Bold" Foreground="#B075D5" Canvas.Left="106" Canvas.Top="19" Visibility="Collapsed"/>
   <TextBlock x:Name="SleepText" Text="Zzz" FontSize="18" FontWeight="Bold" Foreground="#8B6AA9" Canvas.Left="102" Canvas.Top="25" Visibility="Collapsed"/>
  </Canvas>
  <!-- Popup lives outside the 170-pixel pet canvas: speech stays ABOVE the head. -->
  <Popup x:Name="SpeechPopup" Placement="AbsolutePoint" HorizontalOffset="5" VerticalOffset="5"
         AllowsTransparency="True" StaysOpen="True" IsOpen="False" IsHitTestVisible="False">
   <Border x:Name="Speech" Background="BUBBLEFILL" BorderBrush="BUBBLEBORDER" BorderThickness="1"
           CornerRadius="11" Padding="8,5" MaxWidth="148" Visibility="Collapsed">
    <TextBlock x:Name="SpeechText" Text="Γεια σου!" Foreground="#463D42" FontFamily="Segoe UI"
               FontSize="12.5" FontWeight="SemiBold" TextWrapping="Wrap" TextAlignment="Center"/>
   </Border>
  </Popup>
 </Canvas>
</Window>
'@
 return $x.Replace('PETNAME',$name).Replace('HEADS',$head).Replace('BODYS',$body).Replace('LIMBS',$limb).Replace('EARS',$ear).Replace('FACES',$face).Replace('PATCHES',$patch).Replace('TUMMYS',$tummy).Replace('CHEEKS',$cheeks).Replace('INNEREAR',$innerEar).Replace('FOOTCOLOR',$footColor).Replace('BOWVIS',$bowVisibility).Replace('BUBBLEFILL',$bubbleFill).Replace('BUBBLEBORDER',$bubbleBorder)
}

# Χριστουγεννιάτικο δέντρο: ξεχωριστό μη διαδραστικό WPF παράθυρο.
# Δεν αποτελεί wallpaper ούτε στατική εικόνα: ανάβει κατά το στάδιο της πρίζας.
function Get-ChristmasTreeXaml {
 return @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Width="188" Height="238" WindowStyle="None" AllowsTransparency="True"
 Background="Transparent" ShowInTaskbar="False" ShowActivated="False"
 Topmost="True" ResizeMode="NoResize" IsHitTestVisible="False"
 Title="Bubu Dudu - Christmas Tree">
 <Canvas Width="188" Height="238" Background="Transparent" IsHitTestVisible="False">
  <Ellipse Width="122" Height="13" Fill="#24000000" Canvas.Left="35" Canvas.Top="224"/>
  <Rectangle Width="23" Height="48" Fill="#8D6044" Stroke="#644637" StrokeThickness="2" Canvas.Left="84" Canvas.Top="180" RadiusX="3" RadiusY="3"/>
  <Path Data="M 94,12 L 52,82 L 68,81 L 30,150 L 53,147 L 13,204 Q 94,233 174,204 L 136,147 L 158,151 L 119,81 L 137,82 Z"
        Fill="#31865C" Stroke="#275F49" StrokeThickness="4.6" StrokeLineJoin="Round"/>
  <Path Data="M 94,20 L 77,74 L 90,70 L 60,135 L 74,131 L 40,198 Q 75,213 95,211 Z"
        Fill="#66B67B" Opacity="0.52"/>
  <Path Data="M 49,112 Q 93,134 142,111 M 27,172 Q 93,201 161,170"
        Stroke="#E5E7D8" StrokeThickness="5" Fill="Transparent" StrokeStartLineCap="Round" Opacity="0.84"/>
  <Ellipse Width="16" Height="16" Fill="#ED6B72" Stroke="#F8C4BE" StrokeThickness="2" Canvas.Left="88" Canvas.Top="70"/>
  <Ellipse Width="13" Height="13" Fill="#FFD67A" Stroke="#FEEDBE" StrokeThickness="2" Canvas.Left="52" Canvas.Top="114"/>
  <Ellipse Width="16" Height="16" Fill="#E7768E" Stroke="#FAC6CE" StrokeThickness="2" Canvas.Left="122" Canvas.Top="134"/>
  <Ellipse Width="13" Height="13" Fill="#64BBDF" Stroke="#C8EDFF" StrokeThickness="2" Canvas.Left="78" Canvas.Top="176"/>
  <Ellipse Width="14" Height="14" Fill="#F4CC68" Stroke="#FFF5B9" StrokeThickness="2" Canvas.Left="116" Canvas.Top="187"/>
  <Path Data="M 93,47 L 93,56 M 86,52 L 100,52" Stroke="#FFF2D3" StrokeThickness="2"/>
  <Path Data="M 35,161 L 42,169 M 42,161 L 35,169" Stroke="#FFF1DC" StrokeThickness="2"/>
  <Path Data="M 146,151 L 153,159 M 153,151 L 146,159" Stroke="#FFF1DC" StrokeThickness="2"/>
  <Canvas x:Name="TreeLights" Width="188" Height="238">
   <Ellipse x:Name="TreeBulb01" Width="8" Height="9" Fill="#FFE77F" Canvas.Left="91" Canvas.Top="43"/>
   <Ellipse x:Name="TreeBulb02" Width="8" Height="9" Fill="#7EE9FF" Canvas.Left="69" Canvas.Top="86"/>
   <Ellipse x:Name="TreeBulb03" Width="8" Height="9" Fill="#FF97C0" Canvas.Left="117" Canvas.Top="95"/>
   <Ellipse x:Name="TreeBulb04" Width="8" Height="9" Fill="#FDE274" Canvas.Left="93" Canvas.Top="118"/>
   <Ellipse x:Name="TreeBulb05" Width="8" Height="9" Fill="#9DFF85" Canvas.Left="53" Canvas.Top="150"/>
   <Ellipse x:Name="TreeBulb06" Width="8" Height="9" Fill="#FF8B8B" Canvas.Left="134" Canvas.Top="165"/>
   <Ellipse x:Name="TreeBulb07" Width="8" Height="9" Fill="#69CFFB" Canvas.Left="74" Canvas.Top="200"/>
   <Ellipse x:Name="TreeBulb08" Width="8" Height="9" Fill="#FFE478" Canvas.Left="111" Canvas.Top="208"/>
  </Canvas>
  <!-- Το κανονικό αστέρι μένει εκτός δέντρου: η Bubu το βάζει στον Dudu. -->
  <Path Data="M 36,204 L 36,217 M 150,204 L 150,217" Stroke="#4E754F" StrokeThickness="2"/>
 </Canvas>
</Window>
'@
}
function Make-ChristmasTree {
 [xml]$xml=Get-ChristmasTreeXaml
 $w=[System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xml))
 $script:xmasTreeWindow=$w
 $script:xmasTreeLights=@(1..8 | ForEach-Object { $w.FindName(('TreeBulb{0:D2}' -f $_)) })
 $w.Left=$script:area.Left+12.0
 $w.Top=$script:area.Bottom-238.0
 # Οπτικά πίσω από τους χαρακτήρες: δημιουργείται πριν από τα pet windows.
 $w.Show();$w.Hide()
}
function Hide-ChristmasScene {
 if($null -ne $script:xmasTreeWindow){$script:xmasTreeWindow.Hide()}
 $script:xmasLightsOn=$false
 $script:xmasStarPlaced=$false
}
function Start-ChristmasScene([double]$now) {
 if($script:pairScene -ne '' -or !(Test-SceneDialogueComplete $now)){return}
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -eq $b -or $null -eq $d -or $b.Drag -or $d.Drag -or !$d.Grounded){return}
 # Το δέντρο μπαίνει στην πλευρά που χωρά καλύτερα στην οθόνη.
 $leftRoom=$d.X-$script:area.Left
 $rightRoom=$script:area.Right-($d.X+154.0)
 $script:xmasTreeSide=if($leftRoom -ge $rightRoom){-1}else{1}
 $script:xmasBubuTargetX=[math]::Max($script:area.Left+4.0,[math]::Min($script:area.Right-154.0,$d.X-$script:xmasTreeSide*114.0))
 $script:xmasLightsOn=$false
 $script:xmasStarPlaced=$false
 $script:xmasStartAt=$now
 $script:pairScene='xmas-decorate'
 $script:pairStepUntil=$now+6.0
 $script:lastPairScene=$now
 $d.Dir=$script:xmasTreeSide
 Set-Mode $d 'xmas-decorate' $now 14.0 'Θα βάλω εγώ τα λαμπάκια στο δέντρο!'
 Set-Mode $b 'xmas-approach' $now 14.0 'Έρχομαι να βοηθήσω, Dudu!'
 Update-ChristmasVisual $now
}
function Begin-ChristmasStar([double]$now) {
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -eq $b -or $null -eq $d){return}
 $b.Dir=-$script:xmasTreeSide
 $d.Dir=$script:xmasTreeSide
 $script:pairScene='xmas-star'
 $script:pairStepUntil=$now+4.8
 Set-Mode $d 'xmas-tangled' $now 5.6 'Ωχ! Τα λαμπάκια τυλίχτηκαν πάνω μου!'
 Set-Mode $b 'xmas-star' $now 5.6 'Χι χι! Σου λείπει μόνο το αστέρι!'
}
function Begin-ChristmasPlug([double]$now) {
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 $script:xmasStarPlaced=$true
 $script:pairScene='xmas-plug'
 $script:pairStepUntil=$now+4.7
 Set-Mode $d 'xmas-look-up' $now 5.4 'Γιατί νιώθω κάτι στην κορυφή μου;'
 Set-Mode $b 'xmas-plug' $now 5.4 'Και τώρα... βάζω την πρίζα!'
}
function Begin-ChristmasLaugh([double]$now) {
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 $script:xmasLightsOn=$true
 $script:pairScene='xmas-laugh'
 $script:pairStepUntil=$now+5.0
 Set-Mode $d 'xmas-look-up' $now 6.3 'Είμαι εγώ το χριστουγεννιάτικο δέντρο;'
 Set-Mode $b 'xmas-laugh' $now 6.3 'Χα χα χα! Φωτίστηκες, Dudu!'
}
function Finish-ChristmasScene([double]$now) {
 Hide-ChristmasScene
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -ne $b){Set-Mode $b 'shy' $now 2.0}
 if($null -ne $d){Set-Mode $d 'shy' $now 2.0}
 Begin-SceneEpilogue 'christmas' $now 2.0
}
# Ενημερώνει μόνο την απεικόνιση. Δεν επιλέγει νέο reaction και δεν μπλοκάρει το timer.
function Update-ChristmasVisual([double]$now) {
 $isScene=$script:pairScene -like 'xmas-*'
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -eq $b -or $null -eq $d){return}
 foreach($p in @($b,$d)){
  foreach($wrap in $p.XmasWraps){$wrap.Visibility='Collapsed'}
  $p.XmasHeadStar.Visibility='Collapsed'
  $p.XmasHeldStar.Visibility='Collapsed'
  $p.XmasOutlet.Visibility='Collapsed'
  $p.XmasPlug.Visibility='Collapsed'
 }
 if(!$isScene){return}
 if($null -ne $script:xmasTreeWindow){
  $treeX=if($script:xmasTreeSide -lt 0){$d.X-178.0}else{$d.X+137.0}
  $treeX=[math]::Max($script:area.Left,[math]::Min($script:area.Right-188.0,$treeX))
  $treeY=[math]::Max($script:area.Top,[math]::Min($script:area.Bottom-238.0,$d.Y-88.0))
  $script:xmasTreeWindow.Left=$treeX
  $script:xmasTreeWindow.Top=$treeY
  if(!$script:xmasTreeWindow.IsVisible){$script:xmasTreeWindow.Show()}
 }
 $lit=$script:xmasLightsOn
 foreach($light in $script:xmasTreeLights){
  $light.Opacity=if($lit){0.75+0.25*[math]::Abs([math]::Sin($now*4.0+$script:frame*0.03))}else{0.22}
 }
 if($script:pairScene -eq 'xmas-decorate'){
  $elapsed=$now-$d.ModeStart
  $number=[math]::Max(1,[math]::Min(4,1+[math]::Floor($elapsed/1.7)))
 }else{$number=4}
 for($i=0;$i -lt $number;$i++){$d.XmasWraps[$i].Visibility='Visible'}
 foreach($light in $d.XmasBulbs){$light.Opacity=if($lit){0.82+0.18*[math]::Abs([math]::Sin($now*5.0+$light.Name.Length))}else{0.35}}
 # Τα ανοιχτόχρωμα φωτοστέφανα μένουν σχεδόν σβηστά πριν από τη σύνδεση.
 foreach($wrap in $d.XmasWraps){
  foreach($child in $wrap.Children){
   if($child -is [System.Windows.Shapes.Ellipse] -and $child.Width -ge 16){
    $child.Opacity=if($lit){0.64}else{0.05}
   }
  }
 }
 if($script:pairScene -eq 'xmas-star' -and $now-$b.ModeStart -ge 1.7){$script:xmasStarPlaced=$true}
 if($script:xmasStarPlaced){
  $d.XmasHeadStar.Visibility='Visible'
  $d.XmasHeadStar.Opacity=if($lit){0.90+0.10*[math]::Sin($now*6.0)*[math]::Sin($now*6.0)}else{1.0}
 }
 if($script:pairScene -eq 'xmas-star' -and !$script:xmasStarPlaced){
  $b.XmasHeldStar.Visibility='Visible'
  # Το αστέρι ακολουθεί το ήδη υπολογισμένο χέρι της Bubu.
  [System.Windows.Controls.Canvas]::SetLeft($b.XmasHeldStar,$b.WristRX-15.0)
  [System.Windows.Controls.Canvas]::SetTop($b.XmasHeldStar,$b.WristRY-35.0)
 }
 if($script:pairScene -in @('xmas-plug','xmas-laugh')){
  $b.XmasOutlet.Visibility='Visible'
  $b.XmasPlug.Visibility='Visible'
  $progress=if($script:pairScene -eq 'xmas-plug'){
   [math]::Max(0.0,[math]::Min(1.0,($now-$b.ModeStart)/1.7))
  }else{1.0}
  [System.Windows.Controls.Canvas]::SetLeft($b.XmasPlug,(-12.0+16.0*$progress))
 }
}

function Set-Rotation($control,[double]$angle) {
 $rotation=$control.RenderTransform -as [System.Windows.Media.RotateTransform]
 if($null -ne $rotation){$rotation.Angle=$angle}
}
function Set-Mode($p,[string]$mode,[double]$now,[double]$duration,[string]$say='') {
 if($mode -eq 'tumble'){$mode='idle';$say=''} # Απενεργοποιημένη κωλοτούμπα.
 $p.Mode=$mode;$p.Until=$now+$duration;$p.ModeStart=$now
 if($mode -eq 'tumble') {
  $p.TumbleX=$p.X;$p.TumbleY=$p.Y;$p.TumbleDir=$p.Dir;$p.VY=0
 }
 # Ο χρόνος της ομιλίας είναι ανεξάρτητος από τη διάρκεια του animation.
 # Κάθε νέα ατάκα μπαίνει σε FIFO και καμία δεν αντικαθιστά προηγούμενη.
 if(![string]::IsNullOrWhiteSpace($say)){Queue-PetSpeech $p $say $now}
 # Ένα χασμουρητό μπορεί να δημιουργήσει αίτημα για κοινό ύπνο.
 if($mode -in @('yawn','sleep')){
  if($now-$script:lastSleepScene -ge $script:sleepCooldown){
   $script:sleepRequestName=$p.Name
   $script:sleepRequestUntil=$now+24.0
  }
 }
}

# Εμφάνιση μίας ατάκας για περιορισμένο χρόνο ανάγνωσης (2.7–5.3 s).
# Υπάρχει μόνο ένας ενεργός ομιλητής κάθε στιγμή σε όλο το reaction.
function Show-PetSpeechNow($p,[string]$line,[double]$now){
 foreach($other in $script:pets){
  if($null -ne $other -and $other.Name -ne $p.Name){$other.Speech.Visibility='Collapsed'}
 }
 $p.SpeechText.Text=$line
 $p.Speech.Visibility='Visible'
 $reading=[math]::Max(2.7,[math]::Min(5.3,1.35+$line.Length*0.070))
 $p.SpeechHoldUntil=$now+$reading
 $script:speechOwnerName=$p.Name
 $script:lastSpeakerName=$p.Name
}

# Παγκόσμια ουρά με σειρά προτεραιότητας ανά ατάκα, ώστε να μην υπάρχουν ταυτόχρονες ομιλίες.
function Queue-PetSpeech($p,[string]$line,[double]$now){
 if([string]::IsNullOrWhiteSpace($line)){return}
 if($p.Speech.Visibility -eq 'Visible' -and $p.SpeechText.Text -eq $line){return}
 if($p.SpeechQueue.Count -gt 0 -and [string]$p.SpeechQueue[$p.SpeechQueue.Count-1].Text -eq $line){return}
 $script:speechSeq+=1
 [void]$p.SpeechQueue.Add([pscustomobject]@{ Text=$line; Seq=[int]$script:speechSeq; Owner=[string]$p.Name; Scene=[string]$script:pairScene })
}
# Συμβατό με τις υπάρχουσες κλήσεις της σκηνής παρηγοριάς.
function Show-PetSpeech($p,[string]$line,[double]$now){
 Queue-PetSpeech $p $line $now
}
# Δεν αφαιρούμε ποτέ ουρά διαλόγων κατά την αλλαγή σταδίου.
# Η ολοκλήρωση του reaction περιμένει τις εκκρεμείς ατάκες.
# Σκηνές και διάλογοι: καμία απόρριψη ατάκας και ενιαίος έλεγχος ολοκλήρωσης.
function Test-PetSpeechDone($p,[double]$now) {
 if($null -eq $p){return $true}
 if($p.SpeechQueue.Count -gt 0){return $false}
 if($p.Speech.Visibility -eq 'Visible' -and $now -lt $p.SpeechHoldUntil){return $false}
 return $true
}
function Test-ReactionBarrier([double]$now) {
 if($now -lt $script:pairStepUntil){return $false}
 return (Test-SceneDialogueComplete $now)
}
function Complete-PairReaction([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $script:pairScene=''
 $script:lastPairScene=$now
 $script:separateSince=0.0
}
function Get-SceneFamily([string]$name) {
 if($name -match '^close-'){return 'close'}
 if($name -match '^pair-'){return 'pair'}
 if($name -match '^kiss-'){return 'kiss'}
 if($name -match '^story-'){return 'story'}
 if($name -match '^xmas-'){return 'christmas'}
 return $name
}
function Update-SpeechSystem([double]$now){
 foreach($pet in $script:pets){
  if($null -ne $pet -and $pet.Speech.Visibility -eq 'Visible' -and $now -ge $pet.SpeechHoldUntil){$pet.Speech.Visibility='Collapsed'}
 }
 $visible=@()
 foreach($pet in $script:pets){
  if($null -eq $pet){continue}
  if($pet.Speech.Visibility -eq 'Visible' -and $now -lt $pet.SpeechHoldUntil){$visible+=,$pet}
 }
 if($visible.Count -gt 1){
  if($visible.Count -eq 2 -and $visible[0].Mode -eq $visible[1].Mode -and
     $visible[0].Mode -in @('pairdance','pairsing','kiss-active')){return}
  $keeper=$null
  foreach($pet in $visible){ if($pet.Name -eq $script:speechOwnerName){$keeper=$pet; break} }
  if($null -eq $keeper){$keeper=$visible[0]}
  foreach($pet in $visible){ if($pet.Name -ne $keeper.Name){$pet.Speech.Visibility='Collapsed'} }
  return
 }
 if($visible.Count -eq 1){
  $script:speechOwnerName=$visible[0].Name
  # Επιτρέπονται δύο συννεφάκια μόνο σε κοινές αυθόρμητες εκδηλώσεις,
  # με τις δύο ατάκες να ανήκουν στο ίδιο στάδιο και όχι σε ερώτηση/απάντηση.
  $partner=if($visible[0].Name -eq 'Bubu'){Get-Pet 'Dudu'}else{Get-Pet 'Bubu'}
  if($null -ne $partner -and $partner.SpeechQueue.Count -gt 0 -and
     $visible[0].Mode -in @('pairdance','pairsing','kiss-active') -and
     $partner.Mode -eq $visible[0].Mode){
   $item=$partner.SpeechQueue[0]
   if((Get-SceneFamily ([string]$item.Scene)) -eq (Get-SceneFamily ([string]$script:pairScene))){
    $partner.SpeechQueue.RemoveAt(0)
    $partner.SpeechText.Text=[string]$item.Text
    $partner.Speech.Visibility='Visible'
    $partner.SpeechHoldUntil=$now+[math]::Max(2.7,[math]::Min(5.3,1.35+([string]$item.Text).Length*0.070))
   }
  }
  return
 }
 foreach($pet in $script:pets){
  if($null -eq $pet){continue}
  if($pet.Speech.Visibility -eq 'Visible' -and $now -ge $pet.SpeechHoldUntil){$pet.Speech.Visibility='Collapsed'}
 }
 $script:speechOwnerName=''
 $bestPet=$null;$bestItem=$null
 foreach($pet in $script:pets){
  if($null -eq $pet -or $pet.SpeechQueue.Count -eq 0){continue}
  $item=$pet.SpeechQueue[0]
  if($null -eq $bestItem -or [int]$item.Seq -lt [int]$bestItem.Seq){
   $bestPet=$pet;$bestItem=$item
  }
 }
 if($null -ne $bestPet -and $null -ne $bestItem){
  $bestPet.SpeechQueue.RemoveAt(0)
  Show-PetSpeechNow $bestPet ([string]$bestItem.Text) $now
 }
}
function Update-PetSpeech($p,[double]$now){
 # Συμβατότητα με παλιότερες κλήσεις. Η πραγματική διαχείριση γίνεται κεντρικά.
 Update-SpeechSystem $now
}

# A stage finishes only after its visible action has run AND both characters
# have spoken all dialogue already queued for this stage. Otherwise the old
# message would be rendered during the next scene, out of context.
function Test-SceneDialogueComplete([double]$now) {
 foreach($pet in $script:pets){
  if($null -eq $pet){continue}
  if($pet.SpeechQueue.Count -gt 0){return $false}
  if($pet.Speech.Visibility -eq 'Visible' -and $now -lt $pet.SpeechHoldUntil){return $false}
 }
 return $true
}
function Gate-SceneAdvance([double]$now) {
 if($script:pairScene -eq '' -or $now -lt $script:pairStepUntil){return}
 if(!(Test-SceneDialogueComplete $now)){
  # Extend the current animation by a single frame while the speech finishes.
  # Never discard the line or advance the scenario behind the subtitles.
  $script:pairStepUntil=$now+0.10
  foreach($pet in $script:pets){
   if($null -ne $pet -and $pet.Until -lt $script:pairStepUntil){$pet.Until=$script:pairStepUntil}
  }
 }
}
function Begin-SceneEpilogue([string]$tag,[double]$now,[double]$duration) {
 $script:pairScene="epilogue-$tag"
 $script:pairStepUntil=$now+$duration
 $script:lastPairScene=$now
 $script:separateSince=0.0
}
# Finite approach times are only checkpoints, not scene cancellation timers.
# Continue the approach until the characters meet; manual dragging is the
# explicit way to abort a scene (the user is taking control).
function Extend-SceneApproach([double]$now,$a,$b) {
 $script:pairStepUntil=$now+4.0
 foreach($pet in @($a,$b)){
  if($null -eq $pet){continue}
  $pet.Until=[math]::Max($pet.Until,$now+4.2)
  $other=if($pet.Name -eq $a.Name){$b}else{$a}
  if($null -ne $other){$pet.Dir=if($other.X -ge $pet.X){1}else{-1}}
 }
}

function Cancel-PairScene([double]$now) {
 if($script:pairScene -like 'xmas-*'){Hide-ChristmasScene}
 if($null -ne $script:learnPending){$script:learnCancelled=$true}
 foreach($pet in $script:pets){
  if($null -ne $pet -and !$pet.Drag){Set-Mode $pet 'walk' $now 2.5}
 }
 $script:pairScene=''
 $script:storyKind='';$script:storyOwner=''
 $script:pairStepUntil=0.0
 $script:lastPairScene=$now
 $script:nextStory=[math]::Max($script:nextStory,$now+16.0)
 $script:separateSince=0.0
}

function Refresh-Platforms {
 $sx=1.0;$sy=1.0
 $src=[System.Windows.PresentationSource]::FromVisual($script:pets[0].W)
 if($null -ne $src -and $null -ne $src.CompositionTarget) {
  $sx=$src.CompositionTarget.TransformFromDevice.M11
  $sy=$src.CompositionTarget.TransformFromDevice.M22
 }
 $script:platforms=@([PetWin]::Windows([System.Diagnostics.Process]::GetCurrentProcess().Id) | ForEach-Object {
  [pscustomobject]@{L=$_.L*$sx;R=$_.Rgt*$sx;T=$_.T*$sy;B=$_.B*$sy}
 })
}

function Face-Each-Other($a,$b) {
 if($a.X -le $b.X){$a.Dir=1;$b.Dir=-1}else{$a.Dir=-1;$b.Dir=1}
}
function Get-Pet([string]$name) {
 return $script:pets | Where-Object { $_.Name -eq $name } | Select-Object -First 1
}

function Get-PartnerName($p) {
 if($p.Name -eq 'Bubu'){ return 'Dudu' } else { return 'Bubu' }
}
function Say-Love($p) {
 if($p.Name -eq 'Bubu'){ return 'Σ'' αγαπώ Dudu!' } else { return 'Σ'' αγαπώ Bubu!' }
}
function Say-Hello($p) {
 if($p.Name -eq 'Bubu'){ return 'Γεια σου Dudu!' } else { return 'Γεια σου Bubu!' }
}

# Κοινές κινήσεις: πρώτα πλησιάζουν και ΜΕΤΑ ξεκινά η αγκαλιά ή ο χορός.
# Οι αποστάσεις υπολογίζονται μεταξύ των δύο ίδιων σημείων αναφοράς των pets.
function Start-CloseInteraction([string]$kind,[double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag -or $bubu.Mode -eq 'cry'){return}
 if($script:pairScene -ne ''){return}
 if($kind -notin @('hug','dance')){return}
 Face-Each-Other $bubu $dudu
 $script:pairScene="close-$kind-approach"
 $script:pairStepUntil=$now+11.0
 $script:lastPairScene=$now
 $sayB=if($kind -eq 'hug'){'Dudu, έλα αγκαλιά!'}else{'Dudu, πάμε να χορέψουμε!'}
 $sayD=if($kind -eq 'hug'){'Έρχομαι, Bubu!'}else{'Μαζί σου, Bubu!'}
 Set-Mode $bubu 'close-approach' $now 12.0 $sayB
 Set-Mode $dudu 'close-approach' $now 12.0 $sayD
}
function Begin-CloseInteraction([string]$kind,[double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 Face-Each-Other $bubu $dudu
 if($kind -eq 'hug') {
  $duration=3.8
  Set-Mode $bubu 'hug' $now $duration "Σ' αγαπώ, Dudu!"
  Set-Mode $dudu 'hug' $now $duration 'Κι εγώ, Bubu!'
 } else {
  $duration=5.0
  Set-Mode $bubu 'pairdance' $now $duration 'Χορεύουμε μαζί!'
  Set-Mode $dudu 'pairdance' $now $duration 'Ένα, δύο, τρία!'
 }
 $script:pairScene="close-$kind-active"
 $script:pairStepUntil=$now+$duration
}
function End-CloseInteraction([double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -ne $bubu -and $null -ne $dudu){
  Set-Mode $bubu 'shy' $now 1.6 'Χι χι!'
  Set-Mode $dudu 'heart' $now 1.6 'Τι ωραία!'
 }
 Begin-SceneEpilogue 'close' $now 1.6
}

function Start-MeetScene([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 Face-Each-Other $bubu $dudu
 $pick=$script:random.Next(9)
 switch($pick) {
  0 {
   Start-CloseInteraction 'hug' $now
  }
  1 {
   Start-CloseInteraction 'dance' $now 
  }
  2 {
   $script:pairScene='meet-eat'
   $script:pairStepUntil=$now+4.5
   Set-Mode $bubu 'duoeat' $now 4.5 'Τρως μαζί μου, Dudu;'
   Set-Mode $dudu 'duoeat' $now 4.5 'Ναι Bubu!' 
  }
  3 { Start-GiftScene $now }
  4 { Start-PairActivity 'flower' $now }
  5 { Start-PairActivity 'sleep' $now }
  6 { Start-PairActivity 'sing' $now }
  7 { Start-KissScene $now }
  default {
   $script:pairScene='meet-love'
   $script:pairStepUntil=$now+3.2
   Set-Mode $bubu 'heart' $now 3.2 (Say-Love $bubu)
   Set-Mode $dudu 'heart' $now 3.2 (Say-Love $dudu)
  }
 }
 $bubu.LastHeart=$now;$dudu.LastHeart=$now
 $script:lastPairScene=$now
}
function Start-KissScene([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag -or $bubu.Mode -eq 'cry'){return}
 if($script:pairScene -ne ''){return}
 Face-Each-Other $bubu $dudu
 $script:pairScene='kiss-approach'
 $script:pairStepUntil=$now+11.0
 $script:lastPairScene=$now
 Set-Mode $bubu 'kiss-approach' $now 12.0 'Dudu, ένα φιλάκι!'
 Set-Mode $dudu 'kiss-approach' $now 12.0 'Έρχομαι, Bubu!'
}
function Continue-KissScene([double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 Face-Each-Other $bubu $dudu
 Set-Mode $bubu 'kiss-active' $now 3.0 'Μουτς, Dudu! ♥'
 Set-Mode $dudu 'kiss-active' $now 3.0 'Μουτς, Bubu! ♥'
 $script:pairScene='kiss-active'
 $script:pairStepUntil=$now+3.0
}
function Finish-KissScene([double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 Set-Mode $bubu 'shy' $now 2.6 'Σ'' αγαπώ, Dudu!'
 Set-Mode $dudu 'heart' $now 2.6 'Κι εγώ, Bubu!'
 Begin-SceneEpilogue 'kiss' $now 2.6
}

function Start-ComfortScene([double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag){return}
 if($script:pairScene -eq 'comfort' -or $script:pairScene -eq 'comfort-dance'){return}
 $script:pairScene='comfort'
 $script:pairStepUntil=$now+26.0
 $script:lastRescueStarted=$now
 $script:lastComfort=$now
 $script:lastPairScene=$now
 # Ο Dudu παρατάει άμεσα ό,τι έκανε. Η Bubu συνεχίζει να κλαίει μέχρι την αγκαλιά.
 if($dudu.X -lt $bubu.X){$dudu.Dir=1}else{$dudu.Dir=-1}
 $bubu.Mode='cry';$bubu.Until=$now+27.0;$bubu.ModeStart=$now
 Show-PetSpeech $bubu 'Dudu, μου λείπεις!' $now
 Set-Mode $dudu 'rescue' $now 27.0 'Έρχομαι Bubu!'
}

function Start-GiftScene([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag){return}
 Face-Each-Other $bubu $dudu
 $script:pairScene='gift-approach'
 $script:pairStepUntil=$now+9
 $script:lastPairScene=$now
 Set-Mode $dudu 'gift-approach' $now 9.0 'Bubu, σου έφερα γλυκάκι!'
 Set-Mode $bubu 'food-run' $now 9.0 'Μμμ, γλυκάκι! Έρχομαι Dudu!' 
}

function Start-FoodSmellScene([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag -or $bubu.Mode -eq 'cry'){return}
 if($script:pairScene -ne ''){return}
 $script:pairScene='food-smell'
 $script:pairStepUntil=$now+14.0
 $script:lastFoodSmell=$now
 $script:lastPairScene=$now
 Set-Mode $dudu 'food-offer' $now 14.5 'Bubu, έχω λιχουδιές!'
 Set-Mode $bubu 'food-run' $now 14.5 'Μμμ! Μυρίζει γλυκάκι, Dudu!'
}

function Start-PairActivity([string]$kind,[double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag){return}
 if($script:pairScene -ne ''){return}
 if($kind -eq 'sleep' -and $now-$script:lastSleepScene -lt $script:sleepCooldown){return}
 Face-Each-Other $bubu $dudu
 $script:pairScene="pair-$kind-approach"
 $script:pairStepUntil=$now+10
 $script:lastPairScene=$now
 switch($kind){
  'flower' {
   Set-Mode $dudu 'pair-approach' $now 11.0 'Bubu, σου έφερα λουλουδάκι!'
   Set-Mode $bubu 'pair-wait' $now 11.0 'Για μένα, Dudu;'
  }
  'sleep' {
   # Who said 'sleepy' is the inviter, not always Dudu or whichever has less energy.
   $sleepy=$dudu;$helper=$bubu
   if($script:sleepRequestName -eq 'Bubu' -or ($script:sleepRequestName -eq '' -and $bubu.Energy -lt $dudu.Energy)){
    $sleepy=$bubu;$helper=$dudu
   }
   if($sleepy.Name -eq 'Bubu'){
    $askLine='Dudu, νυστάζω... έλα να κοιμηθούμε αγκαλιά!'
    $replyLine='Έρχομαι, Bubu! Θα σε σκεπάσω κιόλας.'
   } else {
    $askLine='Bubu, νυστάζω... έρχεσαι να κοιμηθούμε αγκαλιά;'
    $replyLine='Έρχομαι, Dudu! Θα ξαπλώσουμε μαζί.'
   }
   # Only the helper approaches. The sleepy pet waits and asks for company.
   Set-Mode $sleepy 'pair-wait' $now 11.0 $askLine
   Set-Mode $helper 'pair-approach' $now 11.0 $replyLine
   $script:sleepRequestName='';$script:sleepRequestUntil=0.0
   $script:lastSleepScene=$now
  }
  'sing' {
   Set-Mode $dudu 'pair-approach' $now 11.0 'Bubu, τραγουδάμε μαζί;'
   Set-Mode $bubu 'pair-wait' $now 11.0 'Ναι Dudu, λα λα λα!'
  }
 }
}
function Continue-PairActivity([string]$kind,[double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 Face-Each-Other $bubu $dudu
 switch($kind){
  'flower' {
   Set-Mode $dudu 'flower-give' $now 5.4 'Ένα λουλούδι για σένα, Bubu!'
   Set-Mode $bubu 'flower-receive' $now 5.4 'Είναι πανέμορφο, Dudu!'
   $duration=5.4
  }
  'sleep' {
   # Shared breathing under the two matching halves of the pink blanket.
   Set-Mode $dudu 'pairsleep' $now 17.0 'Καληνύχτα, Bubu! Κοιμήσου αγκαλιά μου.'
   Set-Mode $bubu 'pairsleep' $now 17.0 'Καληνύχτα, Dudu! Σκέπασέ μας καλά!'
   $duration=17.0
  }
  'sing' {
   Set-Mode $dudu 'pairsing' $now 7.5 'Λα λα λα, Bubu! ♫'
   Set-Mode $bubu 'pairsing' $now 7.5 'Τραγουδάμε μαζί, Dudu! ♫'
   $duration=7.5
  }
 }
 $script:pairScene="pair-$kind-active"
 $script:pairStepUntil=$now+$duration
}
function Finish-PairActivity([double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($script:pairScene -eq 'pair-sleep-active'){
  Set-Mode $dudu 'shy' $now 3.0 'Καλημέρα, Bubu! Ξεκουράστηκες;'
  Set-Mode $bubu 'heart' $now 3.0 'Ναι, Dudu! Τι ωραία αγκαλιά!'
  $bubu.Energy=Clamp-Drive ($bubu.Energy+32.0)
  $dudu.Energy=Clamp-Drive ($dudu.Energy+32.0)
  Begin-SceneEpilogue 'sleep' $now 3.0
 } else {
  Set-Mode $dudu 'heart' $now 3.0 (Say-Love $dudu)
  Set-Mode $bubu 'heart' $now 3.0 (Say-Love $bubu)
  Begin-SceneEpilogue 'pair' $now 3.0
 }
}

function Start-HammerScene([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 if($bubu.Drag -or $dudu.Drag -or $bubu.Mode -eq 'cry'){return}
 if($script:pairScene -ne ''){return}
 $script:pairScene='hammer-chase'
 $script:pairStepUntil=$now+9.0
 $script:lastHammerChase=$now
 $script:lastPairScene=$now
 # Keep the comedy chase non-contact and interruptible by a crying Bubu.
 $bubu.Dir=if($dudu.X -gt $bubu.X){1}else{-1}
 $dudu.Dir=-$bubu.Dir
 Set-Mode $bubu 'hammer-run' $now 9.2 'Dudu! Θα σε πιάσω!'
 Set-Mode $dudu 'hammer-flee' $now 9.2 'Αχ, Bubu! Τρέχω!'
}
function End-HammerScene([double]$now) {
 $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
 if($null -eq $bubu -or $null -eq $dudu){return}
 Set-Mode $bubu 'laugh' $now 2.8 'Χα χα! Πλάκα κάνω, Dudu!'
 Set-Mode $dudu 'laugh' $now 2.8 'Χα χα! Με τρόμαξες, Bubu!'
 Begin-SceneEpilogue 'hammer' $now 2.8
}

# Personality values are bounded and updated at one-second intervals, not every frame.
function Clamp-Drive([double]$x) {return [math]::Max(0.0,[math]::Min(100.0,$x))}
function Update-Personality([double]$now) {
 $elapsed=$now-$script:lastPersonalityTick
 if($elapsed -lt 1.0){return}
 $script:lastPersonalityTick=$now
 $elapsed=[math]::Min(3.0,$elapsed)
 foreach($p in $script:pets){
  $p.Hunger=Clamp-Drive ($p.Hunger+0.28*$elapsed)
  $p.AffectionNeed=Clamp-Drive ($p.AffectionNeed+0.22*$elapsed)
  if($p.Mode -in @('walk','food-run','rescue','hammer-run','hammer-flee','pairdance','dance','close-approach','xmas-approach','story-run','story-walk','story-travel')){$p.Energy=Clamp-Drive ($p.Energy-0.30*$elapsed)}
  if($p.Mode -in @('sleep','pairsleep')){$p.Energy=Clamp-Drive ($p.Energy+1.8*$elapsed)}
  elseif($p.Mode -in @('idle','story-sit','story-pc')){$p.Energy=Clamp-Drive ($p.Energy+0.50*$elapsed)}
  if($p.Mode -in @('eat','duoeat','gift-receive')){$p.Hunger=Clamp-Drive ($p.Hunger-3.8*$elapsed)}
  if($p.Mode -in @('hug','kiss-active','heart','pairdance')){
   $p.AffectionNeed=Clamp-Drive ($p.AffectionNeed-4.2*$elapsed)
   $p.Happiness=Clamp-Drive ($p.Happiness+2.3*$elapsed)
   $p.Stress=Clamp-Drive ($p.Stress-2.8*$elapsed)
  }
  if($p.Mode -eq 'cry'){$p.Stress=Clamp-Drive ($p.Stress+1.5*$elapsed)}
  if($p.Mode -eq 'story-scold'){$p.Stress=Clamp-Drive ($p.Stress+0.8*$elapsed)}
  if($p.Mode -eq 'story-apology'){$p.Stress=Clamp-Drive ($p.Stress-3.5*$elapsed)}
  if($p.Mode -eq 'story-pc' -and $p.Name -eq 'Dudu'){$p.Happiness=Clamp-Drive ($p.Happiness+0.15*$elapsed)}
  # Bubu: περισσότερο παιχνίδι και επικοινωνία, Dudu: ηρεμία και φροντίδα.
  if($p.Name -eq 'Bubu'){
   if($p.Mode -in @('dance','pairdance','story-photo','hammer-run','laugh')){$p.Happiness=Clamp-Drive ($p.Happiness+0.48*$elapsed)}
   if($p.Mode -eq 'story-pc'){$p.AffectionNeed=Clamp-Drive ($p.AffectionNeed+0.65*$elapsed)}
  }else{
   if($p.Mode -in @('flower-give','gift-give','rescue','hug','pairsleep')){$p.Happiness=Clamp-Drive ($p.Happiness+0.42*$elapsed)}
   if($p.Mode -eq 'story-pc'){$p.Stress=Clamp-Drive ($p.Stress-0.30*$elapsed)}
  }
  $p.Stress=Clamp-Drive ($p.Stress-0.07*$elapsed)
 }
}
function Start-Story([string]$kind,[double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 if($script:pairScene -ne ''){return}
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -eq $b -or $null -eq $d -or $b.Drag -or $d.Drag -or $b.Mode -eq 'cry'){return}
 if($kind -notin @('scold','stick','pc','photo','travel')){return}
 $script:storyKind=$kind;$script:storyPhase=0
$script:travelDirection=1
 $script:lastStory=$now;$script:lastPairScene=$now
 if($kind -eq 'stick'){
  $actor=if($script:random.Next(100) -lt 60){$b}else{$d}
  $visitor=if($actor.Name -eq 'Bubu'){$d}else{$b}
  $script:storyOwner=$actor.Name
  $script:pairScene='story-stick-play'
  $script:pairStepUntil=$now+4.5
  Set-Mode $actor 'story-sit' $now 5.2 'Θα σκαλίσω λίγο το χώμα...'
  Set-Mode $visitor 'story-notice' $now 5.2 'Τι κάνει εκεί μόνο του;'
  return
 }
 if($kind -eq 'pc'){
  $script:storyOwner='Dudu'
  $script:pairScene='story-pc-work'
  $script:pairStepUntil=$now+5.5
  Set-Mode $d 'story-pc' $now 6.3 'Λίγο ακόμη στον υπολογιστή...'
  Set-Mode $b 'story-notice' $now 6.3 'Duduuu, κοίτα με!'
  return
 }
 Face-Each-Other $b $d
 if($kind -eq 'scold'){
  # First come together; no arguing and apologizing from opposite screen edges.
  $script:pairScene='story-scold-approach'
  $script:pairStepUntil=$now+11.0
  Set-Mode $b 'story-walk' $now 11.0 'Dudu, θέλω να σου μιλήσω!'
  Set-Mode $d 'story-walk' $now 11.0 'Έρχομαι, Bubu...'
  return
 }
 if($kind -eq 'photo'){
  $script:pairScene='story-photo-approach'
  $script:pairStepUntil=$now+10.0
  Set-Mode $b 'story-walk' $now 10.5 'Dudu, φωτογραφία μαζί!'
  Set-Mode $d 'story-walk' $now 10.5 'Έρχομαι, Bubu!'
  return
 }
 if($kind -eq 'travel'){
  $script:pairScene='story-travel-approach'
  $script:pairStepUntil=$now+10.0
  Set-Mode $b 'story-walk' $now 10.5 'Πάμε ταξίδι, Dudu!'
  Set-Mode $d 'story-walk' $now 10.5 'Έφερα τη βαλίτσα!'
 }
}
function Begin-StoryHug([double]$now,[string]$lineB,[string]$lineD) {
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 Face-Each-Other $b $d
 Set-Mode $b 'hug' $now 3.4 $lineB
 Set-Mode $d 'hug' $now 3.4 $lineD
 $script:pairScene='story-hug'
 $script:pairStepUntil=$now+3.4
}
function Finish-Story([double]$now) {
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -ne $b -and $null -ne $d){
  Set-Mode $b 'shy' $now 2.0 'Χι χι!'
  Set-Mode $d 'heart' $now 2.0 'Σ'' αγαπώ, Bubu!'
  $b.AffectionNeed=Clamp-Drive ($b.AffectionNeed-18.0)
  $d.AffectionNeed=Clamp-Drive ($d.AffectionNeed-18.0)
 }
 Begin-SceneEpilogue 'story' $now 2.0
 $script:storyKind='';$script:storyOwner=''
 $script:nextStory=$now+23.0+$script:random.NextDouble()*18.0
}
function Advance-Story([double]$now,$b,$d,[double]$dx,[double]$dy) {
 $scene=$script:pairScene
 if($scene -eq 'story-scold-approach'){
  if($dx -lt 104 -and $dy -lt 45 -and (Test-SceneDialogueComplete $now)){
   Face-Each-Other $b $d
   Set-Mode $b 'story-scold' $now 4.2 'Dudu! Πάλι έφαγες το μπισκοτάκι μου;'
   Set-Mode $d 'story-ashamed' $now 4.2 'Εεε... Bubu...'
   $script:pairScene='story-scold';$script:pairStepUntil=$now+3.8
  } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $b $d}
 } elseif($scene -eq 'story-scold' -and $now -ge $script:pairStepUntil){
  Set-Mode $d 'story-apology' $now 3.2 'Συγγνώμη, Bubu! Δεν θα το ξανακάνω.'
  Set-Mode $b 'story-soften' $now 3.2 'Εντάξει... Ήμουν λίγο αυστηρή.'
  $script:pairScene='story-apology-1';$script:pairStepUntil=$now+3.2
 } elseif($scene -eq 'story-apology-1' -and $now -ge $script:pairStepUntil){
  Set-Mode $b 'story-apology' $now 2.6 'Κι εγώ συγγνώμη, Dudu!'
  Set-Mode $d 'story-soften' $now 2.6 'Όλα καλά, Bubu!'
  $script:pairScene='story-apology-2';$script:pairStepUntil=$now+2.6
 } elseif($scene -eq 'story-apology-2' -and $now -ge $script:pairStepUntil){
  $script:pairScene='story-approach'
  $script:pairStepUntil=$now+10.0
  Set-Mode $b 'story-run' $now 10.0 'Έλα να αγκαλιαστούμε!'
  Set-Mode $d 'story-run' $now 10.0 'Με πολλή χαρά!'
 } elseif($scene -eq 'story-stick-play' -and $now -ge $script:pairStepUntil){
  $actor=if($script:storyOwner -eq 'Bubu'){$b}else{$d}
  $visitor=if($actor.Name -eq 'Bubu'){$d}else{$b}
  Set-Mode $actor 'story-sit' $now 11.0 'Έλα να παίξουμε μαζί!'
  Set-Mode $visitor 'story-run' $now 11.0 'Έρχομαι για αγκαλιά!'
  $script:pairScene='story-approach';$script:pairStepUntil=$now+11.0
 } elseif($scene -eq 'story-pc-work' -and $now -ge $script:pairStepUntil){
  Set-Mode $b 'story-run' $now 10.0 'Dudu, θέλω αγκαλίτσα!'
  Set-Mode $d 'story-pc' $now 10.0 'Μια στιγμή, Bubu...'
  $script:pairScene='story-pc-attention';$script:pairStepUntil=$now+10.0
 } elseif($scene -eq 'story-pc-attention'){
  if($dx -lt 99 -and $dy -lt 45 -and (Test-SceneDialogueComplete $now)){
   Set-Mode $d 'story-soften' $now 2.0 'Έκλεισα το laptop, Bubu!'
   Set-Mode $b 'story-soften' $now 2.0 'Επιτέλους!'
   $script:pairScene='story-pc-close';$script:pairStepUntil=$now+2.0
  } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $b $d}
 } elseif($scene -eq 'story-pc-close' -and $now -ge $script:pairStepUntil){
  Begin-StoryHug $now 'Τώρα είσαι δικός μου!' 'Έχεις όλη μου την προσοχή!'
 } elseif($scene -eq 'story-photo-approach'){
  if($dx -lt 94 -and $dy -lt 45 -and (Test-SceneDialogueComplete $now)){
   Face-Each-Other $b $d
   Set-Mode $b 'story-photo' $now 5.0 'Χαμόγελο! Ένα, δύο, τρία!'
   Set-Mode $d 'story-photo' $now 5.0 'Τσίζζζ!'
   $script:pairScene='story-photo-active';$script:pairStepUntil=$now+5.0
  } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $b $d}
 } elseif($scene -eq 'story-photo-active' -and $now -ge $script:pairStepUntil){
  Begin-StoryHug $now 'Βγήκαμε τέλειοι!' 'Να την κρατήσουμε!'
 } elseif($scene -eq 'story-travel-approach'){
  if($dx -lt 114 -and $dy -lt 55 -and (Test-SceneDialogueComplete $now)){
   Face-Each-Other $b $d
   # Μία κοινή κατεύθυνση για όλο το ταξίδι, όχι δύο ανεξάρτητες αποφάσεις.
   $pairMiddle=(($b.X+$d.X)*0.5)+70.0
   $screenMiddle=($script:area.Left+$script:area.Right)*0.5
   $script:travelDirection=if($pairMiddle -lt $screenMiddle){1}else{-1}
   Set-Mode $b 'story-travel' $now 10.0 'Πάμε εκδρομή μαζί!'
   Set-Mode $d 'story-travel' $now 10.0 'Έτοιμες οι βαλίτσες!'
   $script:pairScene='story-travel-active';$script:pairStepUntil=$now+10.0
  } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $b $d}
 } elseif($scene -eq 'story-travel-active' -and $now -ge $script:pairStepUntil){
  Begin-StoryHug $now 'Τι ωραίο ταξίδι!' 'Κάθε ταξίδι μαζί σου!'
 } elseif($scene -eq 'story-approach'){
  if($dx -lt 98 -and $dy -lt 45 -and (Test-SceneDialogueComplete $now)){
   Begin-StoryHug $now 'Μια μεγάλη αγκαλιά!' 'Πάντα μαζί!'
  } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $b $d}
 } elseif($scene -eq 'story-hug' -and $now -ge $script:pairStepUntil){
  Finish-Story $now
 }
}
# Local, explainable utility-AI: needs, temperament, social context and event memory.
# Η μνήμη μειώνει επαναλήψεις. Οι υποψήφιες ιστορίες βαθμολογούνται πριν την επιλογή.
# Κατάσταση/δράση tabular TD learning. Αποφεύγουμε μεγάλη διαστατικότητα.
function Get-LearnState($pet){
 $energy=if($pet.Energy -lt 35){'tired'}elseif($pet.Energy -gt 72){'fresh'}else{'normal'}
 $need=if($pet.AffectionNeed -gt 58){'needy'}elseif($pet.Stress -gt 42){'stressed'}elseif($pet.Hunger -gt 58){'hungry'}else{'balanced'}
 return "$energy/$need"
}
function Get-LearnKey([string]$state,[string]$activity){return "$state|$activity"}
function Get-LearnValue([string]$name,[string]$state,[string]$activity){
 $key=Get-LearnKey $state $activity
 if($script:learnQ[$name].ContainsKey($key)){return [double]$script:learnQ[$name][$key]}
 return 0.0
}
function Get-LearnMax([string]$name,[string]$state){
 $result=0.0
 foreach($activity in $script:learnActions){
  $value=Get-LearnValue $name $state $activity
  if($value -gt $result){$result=$value}
 }
 return $result
}
function Get-LearnReward($pet,$prior,[string]$activity,[bool]$completed){
 if(!$completed){return -0.8}
 # Πρόκειται για συνθετική επιβράβευση βάσει των εσωτερικών μετρητών.
 $gain=0.014*($pet.Happiness-[double]$prior.Happiness) +
       0.013*([double]$prior.Stress-$pet.Stress) +
       0.010*([double]$prior.AffectionNeed-$pet.AffectionNeed) +
       0.006*($pet.Energy-[double]$prior.Energy)
 $trait=0.0
 if($pet.Name -eq 'Bubu' -and $activity -in @('stick','photo','dance','hammer')){$trait=0.10}
 if($pet.Name -eq 'Dudu' -and $activity -in @('pc','gift','flower','hug','sleep')){$trait=0.10}
 if($activity -eq 'sleep' -and [double]$prior.Energy -gt 65){$trait-=0.20}
 if($activity -eq 'scold'){$trait-=0.06}
 return [math]::Max(-1.0,[math]::Min(1.0,0.16+$gain+$trait))
}
function Update-LearnedTraits($pet,[string]$activity,[double]$reward){
 # Ήπια προσαρμογή εντός +/-12 μονάδων από τον αρχικό χαρακτήρα.
 $step=[math]::Max(-0.35,[math]::Min(0.35,0.32*$reward))
 $basePlay=if($pet.Name -eq 'Bubu'){95.0}else{67.0}
 $basePatience=if($pet.Name -eq 'Bubu'){38.0}else{92.0}
 $baseCuriosity=if($pet.Name -eq 'Bubu'){74.0}else{68.0}
 if($activity -in @('stick','photo','dance','hammer')){
  $pet.Playfulness=[math]::Max($basePlay-12,[math]::Min(100.0,$pet.Playfulness+$step))
 }
 if($activity -in @('pc','gift','flower','hug','sleep')){
  $pet.Patience=[math]::Max($basePatience-12,[math]::Min(100.0,$pet.Patience+$step))
 }
 if($activity -in @('pc','travel','photo','stick')){
  $pet.Curiosity=[math]::Max($baseCuriosity-12,[math]::Min(100.0,$pet.Curiosity+$step))
 }
}
function Start-LearningEpisode([string]$activity,[double]$now){
 if($script:learnPending -ne $null -or $activity -notin $script:learnActions){return}
 $snapshot=@{}
 foreach($pet in $script:pets){
  $snapshot[$pet.Name]=[pscustomobject]@{
   State=(Get-LearnState $pet); Happiness=[double]$pet.Happiness
   Stress=[double]$pet.Stress;AffectionNeed=[double]$pet.AffectionNeed;Energy=[double]$pet.Energy
  }
 }
 $script:learnPending=[pscustomobject]@{Activity=$activity;Start=$now;Snapshot=$snapshot}
 $script:learnCancelled=$false
}
function Complete-LearningEpisode([double]$now){
 if($null -eq $script:learnPending){return}
 # Ολοκληρώνεται μόνο όταν έχει τερματιστεί ΚΑΙ η σκηνή ΚΑΙ ο διάλογός της.
 if($script:pairScene -ne '' -or !(Test-SceneDialogueComplete $now)){return}
 $episode=$script:learnPending
 $completed=(!$script:learnCancelled)
 foreach($pet in $script:pets){
  $name=[string]$pet.Name
  $prior=$episode.Snapshot[$name]
  $state=[string]$prior.State
  $activity=[string]$episode.Activity
  $key=Get-LearnKey $state $activity
  $old=Get-LearnValue $name $state $activity
  $reward=Get-LearnReward $pet $prior $activity $completed
  $next=Get-LearnState $pet
  $target=$reward+$script:learnGamma*(Get-LearnMax $name $next)
  $updated=$old+$script:learnAlpha*($target-$old)
  $script:learnQ[$name][$key]=[math]::Max(-3.0,[math]::Min(3.0,$updated))
  $count=0
  if($script:learnCount[$name].ContainsKey($key)){$count=[int]$script:learnCount[$name][$key]}
  $script:learnCount[$name][$key]=$count+1
  if($completed){Update-LearnedTraits $pet $activity $reward}
 }
 $script:learnEpisodes++
 $script:learnPending=$null
 $script:learnCancelled=$false
 Save-LearningMemory
}
function Save-LearningMemory {
 try{
  if(!(Test-Path -LiteralPath $script:learnDirectory)){
   [void][System.IO.Directory]::CreateDirectory($script:learnDirectory)
  }
  $traits=@{}
  foreach($pet in $script:pets){
   $traits[$pet.Name]=@{Playfulness=[double]$pet.Playfulness;Patience=[double]$pet.Patience;Curiosity=[double]$pet.Curiosity}
  }
  $data=@{Version=1;Episodes=[int]$script:learnEpisodes;Q=$script:learnQ;Counts=$script:learnCount;Traits=$traits}
  $json=ConvertTo-Json -InputObject $data -Depth 10 -Compress
  $temp=Join-Path $script:learnDirectory 'learning-v1.tmp'
  [System.IO.File]::WriteAllText($temp,$json,[System.Text.UTF8Encoding]::new($false))
  if(Test-Path -LiteralPath $script:learnPath){
   # Αντικατάσταση με backup, χωρίς ενδιάμεση διαγραφή του παλιού αρχείου.
   $backup=Join-Path $script:learnDirectory 'learning-v1.bak'
   [System.IO.File]::Replace($temp,$script:learnPath,$backup)
  }else{
   [System.IO.File]::Move($temp,$script:learnPath)
  }
 }catch{
  try{Add-Content -Path (Join-Path $PSScriptRoot 'error.log') -Value "Learning save: $($_.Exception.Message)" -Encoding UTF8}catch{}
 }
}
function Load-LearningMemory {
 if(!(Test-Path -LiteralPath $script:learnPath)){return}
 try{
  $data=Get-Content -LiteralPath $script:learnPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if([int]$data.Version -ne 1){return}
  foreach($pet in $script:pets){
   $name=$pet.Name
   foreach($property in $data.Q.$name.PSObject.Properties){
    $key=[string]$property.Name
    if($key -match '^[a-z]+/[a-z]+\|(stick|pc|photo|travel|hammer|scold|hug|dance|kiss|gift|flower|sleep|christmas)$'){
     $val=[double]$property.Value
     if(![double]::IsNaN($val) -and [math]::Abs($val) -le 3.0){$script:learnQ[$name][$key]=$val}
    }
   }
   foreach($property in $data.Counts.$name.PSObject.Properties){
    $key=[string]$property.Name
    if($script:learnQ[$name].ContainsKey($key)){$script:learnCount[$name][$key]=[math]::Max(0,[int]$property.Value)}
   }
   $traits=$data.Traits.$name
   $basePlay=if($name -eq 'Bubu'){95.0}else{67.0}
   $basePatience=if($name -eq 'Bubu'){38.0}else{92.0}
   $baseCuriosity=if($name -eq 'Bubu'){74.0}else{68.0}
   if($null -ne $traits){
    $pet.Playfulness=[math]::Max($basePlay-12,[math]::Min(100.0,[double]$traits.Playfulness))
    $pet.Patience=[math]::Max($basePatience-12,[math]::Min(100.0,[double]$traits.Patience))
    $pet.Curiosity=[math]::Max($baseCuriosity-12,[math]::Min(100.0,[double]$traits.Curiosity))
   }
  }
  $script:learnEpisodes=[math]::Max(0,[int]$data.Episodes)
 }catch{
  try{Add-Content -Path (Join-Path $PSScriptRoot 'error.log') -Value "Learning load: $($_.Exception.Message)" -Encoding UTF8}catch{}
 }
}

function Add-AIMemory([string]$activity,[double]$now) {
 $script:aiLastActivity[$activity]=$now
 $script:aiRecent.Add($activity)
 while($script:aiRecent.Count -gt 7){$script:aiRecent.RemoveAt(0)}
 $script:lastAIDecision=$activity
 $script:aiSocialCount+=1
 $script:aiLastSelectionIndex[$activity]=[int]$script:aiSocialCount
}
function Get-AIRecencyFactor([string]$activity,[double]$now) {
 if(!$script:aiLastActivity.ContainsKey($activity)){return 1.0}
 $age=$now-[double]$script:aiLastActivity[$activity]
 if($age -lt 35){return 0.025}
 if($age -lt 75){return 0.13}
 if($age -lt 125){return 0.38}
 if($age -lt 190){return 0.70}
 return 1.0
}
function Choose-PersonalityStory([double]$now) {
 if(!(Test-SceneDialogueComplete $now)){return}
 if($script:pairScene -ne '' -or $now -lt $script:nextStory -or $now -lt $script:nextSocialAllowed -or !(Test-SceneDialogueComplete $now)){return}
 $b=Get-Pet 'Bubu';$d=Get-Pet 'Dudu'
 if($null -eq $b -or $null -eq $d -or $b.Drag -or $d.Drag -or $b.Mode -eq 'cry' -or $d.Mode -eq 'rescue'){return}
 if($b.Mode -notin @('walk','idle','think','heart','wave') -or $d.Mode -notin @('walk','idle','think','heart','wave')){return}
 $needsLove=[math]::Max($b.AffectionNeed,$d.AffectionNeed)
 $fatigue=100.0-[math]::Min($b.Energy,$d.Energy)
 $stress=[math]::Max($b.Stress,$d.Stress)
 $hungry=[math]::Max($b.Hunger,$d.Hunger)
 $distance=[math]::Sqrt([math]::Pow($b.X-$d.X,2)+[math]::Pow($b.Y-$d.Y,2))
 $playDrive=$b.Playfulness*0.75+$d.Playfulness*0.25
 $calmDrive=$d.Patience*0.80+$b.Patience*0.20
 $weights=@{
  stick=8.0+0.16*$playDrive
  pc=9.0+0.19*$calmDrive
  photo=8.0+0.14*$b.Playfulness
  travel=7.0+0.10*$playDrive
  hammer=4.0+0.12*$b.Playfulness
  scold=1.0+0.07*$b.Stress+0.04*$b.AffectionNeed
  hug=10.0+0.48*$needsLove+0.17*$stress
  dance=8.0+0.17*$playDrive
  kiss=7.0+0.30*$needsLove
  gift=8.0+0.13*$d.Patience+0.12*$hungry
  flower=8.0+0.14*$d.Patience
  sleep=0.1+0.15*[math]::Max(0.0,$fatigue-65.0)
  christmas=11.0+0.15*$playDrive
 }
 # Personality: Bubu initiates playful closeness; Dudu offers care and calmness.
 if($b.Happiness -gt 65){$weights.photo*=1.20;$weights.dance*=1.12;$weights.hammer*=1.15}
 if($b.AffectionNeed -gt 55){$weights.pc*=0.54;$weights.hug*=1.24}
 if($d.Stress -gt 40){$weights.hug*=1.20;$weights.flower*=1.10;$weights.scold*=0.20}
 if($fatigue -gt 65){$weights.dance*=0.18;$weights.travel*=0.20;$weights.hammer*=0.06;$weights.sleep*=1.6;$weights.hug*=1.30}
 if($now-$script:lastSleepScene -lt $script:sleepCooldown){$weights.sleep=0.0}
 if($fatigue -lt 35){$weights.sleep=0.0}
 if($now-$script:lastHammerChase -lt 140){$weights.hammer=0.0}
 if($b.Stress -gt 55 -or $d.Stress -gt 45){$weights.hammer*=0.07}
 if($distance -gt 310){$weights.pc*=1.18;$weights.stick*=1.14;$weights.kiss*=0.75}
 # Conflict must be rare, and never when either bear is upset or exhausted.
 if($b.Stress -lt 17 -or $d.Stress -gt 28 -or $fatigue -gt 55){$weights.scold=0.8}
 # Stronger cooldown and an ordered history prevent repetitive routines.
 foreach($key in @($weights.Keys)){
  $weights[$key]*=Get-AIRecencyFactor $key $now
  if($script:aiRecent.Count -ge 2){
   $prev=$script:aiRecent[$script:aiRecent.Count-1]
   if($prev -eq $key){$weights[$key]*=0.1}
   if($prev -eq 'scold' -and $key -eq 'scold'){$weights[$key]=0.01}
  }
  $weights[$key]=[math]::Max(0.0,[double]$weights[$key])
 }
 # Ενιαίος AI scheduler: οι δραστηριότητες που λείπουν από την πρόσφατη
 # ιστορία αποκτούν επιπλέον βάρος. Δεν υπάρχει άκαμπτη σειρά.
 # Μετά από πολλές άκαρπες επιλογές, το AI επιλέγει ανάμεσα στις
 # πραγματικά παραμελημένες ασφαλείς δραστηριότητες.
 $keys=@('stick','pc','photo','travel','hammer','scold','hug','dance','kiss','gift','flower','sleep','christmas')
 $maxOverdue=0
 foreach($key in $keys){
  if([double]$weights[$key] -le 0.0){continue}
  $lastIndex=0
  if($script:aiLastSelectionIndex.ContainsKey($key)){$lastIndex=[int]$script:aiLastSelectionIndex[$key]}
  $missed=[int]($script:aiSocialCount-$lastIndex)
  if($missed -gt $maxOverdue){$maxOverdue=$missed}
  $novelty=1.0+[math]::Pow([math]::Min(9.0,[double]$missed)/3.0,2.0)*1.8
  $weights[$key]*=$novelty
 }
 # Όταν κάποιο reaction έχει μείνει εκτός για 9 επιλογές, δίνουμε
 # προτεραιότητα στην οφειλόμενη ομάδα, αλλά η τελική επιλογή
 # εντός της ομάδας εξακολουθεί να γίνεται από τα utility scores.
 if($maxOverdue -ge 9){
  foreach($key in $keys){
   if([double]$weights[$key] -le 0.0){continue}
   $lastIndex=0
   if($script:aiLastSelectionIndex.ContainsKey($key)){$lastIndex=[int]$script:aiLastSelectionIndex[$key]}
   if(($script:aiSocialCount-$lastIndex) -lt ($maxOverdue-2)){$weights[$key]*=0.02}
  }
 }
 # Online TD values bias the utility scores, without overriding safety/cooldowns.
 foreach($key in $keys){
  if([double]$weights[$key] -le 0.0){continue}
  $qB=Get-LearnValue 'Bubu' (Get-LearnState $b) $key
  $qD=Get-LearnValue 'Dudu' (Get-LearnState $d) $key
  $learnScore=0.5*($qB+$qD)
  $multiplier=[math]::Exp(0.24*$learnScore)
  $weights[$key]*=[math]::Max(0.55,[math]::Min(1.85,$multiplier))
  if($key -eq 'pc' -or $key -eq 'travel'){
   $curiosity=($b.Curiosity+$d.Curiosity)/2.0
   $weights[$key]*=(0.75+0.25*$curiosity/70.0)
  }
 }
 $total=0.0
 foreach($key in $keys){$total+=[double]$weights[$key]}
 if($total -le 0.0){return}
 $ticket=$script:random.NextDouble()*$total
 $pick='hug'
 foreach($key in $keys){$ticket-=[double]$weights[$key];if($ticket -le 0){$pick=$key;break}}
 $script:nextStory=$now+15.0
 switch($pick){
  'hug' {Start-CloseInteraction 'hug' $now}
  'dance' {Start-CloseInteraction 'dance' $now}
  'kiss' {Start-KissScene $now}
  'gift' {Start-GiftScene $now}
  'flower' {Start-PairActivity 'flower' $now}
  'sleep' {Start-PairActivity 'sleep' $now}
  'hammer' {Start-HammerScene $now}
  'christmas' {Start-ChristmasScene $now}
  default {Start-Story $pick $now}
 }
 if($script:pairScene -ne ''){Add-AIMemory $pick $now;Start-LearningEpisode $pick $now}
}

function Make-Pet([string]$name,[double]$x,[double]$y,[int]$dir) {
 [xml]$xml=Get-Xaml $name
 $window=[System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xml))
 $p=[pscustomobject]@{
  Name=$name;W=$window;X=$x;Y=$y;Dir=$dir;VY=0.0;Drag=$false;DX=0.0;DY=0.0;Partner=$null
  Mode='landing';Until=99999999.0;ModeStart=0.0;LastHeart=0.0;Anim=0.0;Grounded=$false;FoodSeenAt=-100.0;SpeechHoldUntil=0.0;SpeechQueue=([System.Collections.ArrayList]::new());BubbleX=18.0;BubbleY=-54.0;BubbleInitialized=$false;BubbleTargetX=18.0;BubbleTargetY=-54.0;BubbleMessage='';BubbleOwnerVX=0.0;BubbleOwnerVY=0.0;BubblePreviousX=$x;BubblePreviousY=$y;BubbleW=0.0;BubbleH=0.0;SmoothArmL=0.0;SmoothArmR=0.0;SmoothHead=0.0;SmoothBody=0.0;SoloLast='';SoloPrevious='';SoloLastAt=0.0;FootLWorld=0.0;FootRWorld=0.0;FootLPlanted=$false;FootRPlanted=$false;FootLWasSwing=$true;FootRWasSwing=$true;NavStage='';NavStart=0.0;NavHeightY=0.0;NavPlatformL=0.0;NavPlatformR=0.0;NavPlatformTop=0.0;NavEdgeSide=1;NavVX=0.0;NavRetryAfter=0.0;NavLastChoice='';NavChoiceAt=0.0;WalkGoalX=$x;WalkGoalUntil=0.0;WalkSupportId='';WalkReverseAt=0.0;LastMoveX=$x;MoveSpeedX=0.0;SmoothSpeedX=0.0;PatrolSpeed=0.0;GaitPhase=0.0;TurnFrom=$dir;TurnUntil=0.0;FacingDir=$dir;SlopeLean=0.0;StrideScale=1.0;BodyMotionX=0.0;BodyMotionY=0.0;MotionBlend=0.0;GroundFootY=145.0;LastFacing=0;TailPhase=0.0
  Happiness=76.0;Energy=82.0;Hunger=22.0;AffectionNeed=24.0;Stress=8.0
  Playfulness=$(if($name -eq 'Bubu'){95.0}else{67.0});Patience=$(if($name -eq 'Bubu'){38.0}else{92.0});Sensitivity=$(if($name -eq 'Bubu'){87.0}else{66.0});Curiosity=$(if($name -eq 'Bubu'){74.0}else{68.0})
  TumbleX=0.0;TumbleY=0.0;TumbleDir=1;BlinkTime=0.0;NextBlink=1.0;Gaze=0.0;NextGaze=0.0;LookSide=1.0;NextLook=5.0;BackUntil=0.0;NextBack=14.0
  HeadGroup=$window.FindName('HeadGroup');FrontHeadView=$window.FindName('FrontHeadView');ProfileHeadView=$window.FindName('ProfileHeadView');BackHeadView=$window.FindName('BackHeadView');BubuBow=$window.FindName('BubuBow');BubuBowSide=$window.FindName('BubuBowSide');BackBody=$window.FindName('BackBody');FrontFace=$window.FindName('FrontFace');FrontBody=$window.FindName('FrontBody');ProfileBody=$window.FindName('ProfileBody');ProfileEye=$window.FindName('ProfileEye');ProfileGlint=$window.FindName('ProfileGlint');ProfileMouth=$window.FindName('ProfileMouth');ProfileSmile=$window.FindName('ProfileSmile');EarLeft=$window.FindName('EarLeft');EarRight=$window.FindName('EarRight')
  Eye1=$window.FindName('Eye1');Eye2=$window.FindName('Eye2')
  Glint1=$window.FindName('Glint1');Glint2=$window.FindName('Glint2')
  Smile=$window.FindName('Smile');OpenMouth=$window.FindName('OpenMouth')
  SadMouth=$window.FindName('SadMouth');Heart=$window.FindName('Heart')
  SleepText=$window.FindName('SleepText');Art=$window.FindName('Art')
  GroundPlay=$window.FindName('GroundPlay');GroundStick=$window.FindName('GroundStick');MiniLaptop=$window.FindName('MiniLaptop');CameraProp=$window.FindName('CameraProp');SuitcaseProp=$window.FindName('SuitcaseProp');Blanket=$window.FindName('Blanket')
  LegLeft=$window.FindName('LegLeft');LegRight=$window.FindName('LegRight');ThighLeft=$window.FindName('ThighLeft');ShinLeft=$window.FindName('ShinLeft');ThighRight=$window.FindName('ThighRight');ShinRight=$window.FindName('ShinRight');ThighLeftOutline=$window.FindName('ThighLeftOutline');ShinLeftOutline=$window.FindName('ShinLeftOutline');ThighRightOutline=$window.FindName('ThighRightOutline');ShinRightOutline=$window.FindName('ShinRightOutline');TailSide=$window.FindName('TailSide');TailBack=$window.FindName('TailBack')
  ArmLeftUpper=$window.FindName('ArmLeftUpper');ArmLeftLower=$window.FindName('ArmLeftLower');ArmLeftUpperOutline=$window.FindName('ArmLeftUpperOutline');ArmLeftLowerOutline=$window.FindName('ArmLeftLowerOutline');ArmLeftHand=$window.FindName('ArmLeftHand')
  ArmRightUpper=$window.FindName('ArmRightUpper');ArmRightLower=$window.FindName('ArmRightLower');ArmRightUpperOutline=$window.FindName('ArmRightUpperOutline');ArmRightLowerOutline=$window.FindName('ArmRightLowerOutline');ArmRightHand=$window.FindName('ArmRightHand')
  Tear1=$window.FindName('Tear1');Tear2=$window.FindName('Tear2')
  ToyHammer=$window.FindName('ToyHammer');Candy=$window.FindName('Candy');Flower=$window.FindName('Flower');MusicNote=$window.FindName('MusicNote');KissHeart=$window.FindName('KissHeart');Cookie=$window.FindName('Cookie');Crumb1=$window.FindName('Crumb1');Crumb2=$window.FindName('Crumb2')
  Shadow=$window.FindName('Shadow');Speech=$window.FindName('Speech');SpeechPopup=$window.FindName('SpeechPopup');SpeechText=$window.FindName('SpeechText')
  Sweat=$window.FindName('Sweat');Sparkle=$window.FindName('Sparkle')
  XmasWraps=@(1..4 | ForEach-Object { $window.FindName(('XmasWrap{0}' -f $_)) })
  XmasBulbs=@(1..12 | ForEach-Object { $window.FindName(('XmasBulb{0:D2}' -f $_)) })
  XmasHeadStar=$window.FindName('XmasHeadStar');XmasHeldStar=$window.FindName('XmasHeldStar')
  XmasOutlet=$window.FindName('XmasOutlet');XmasPlug=$window.FindName('XmasPlug')
 }
 # One-time transform objects: no per-frame WPF allocations.
 $artTransforms=[System.Windows.Media.TransformGroup]::new()
 $p | Add-Member NoteProperty Flip ([System.Windows.Media.ScaleTransform]::new(1,1))
 $p | Add-Member NoteProperty ArtRotation ([System.Windows.Media.RotateTransform]::new(0))
 $p | Add-Member NoteProperty ArtScale ([System.Windows.Media.ScaleTransform]::new(1,1))
 $p | Add-Member NoteProperty ArtShift ([System.Windows.Media.TranslateTransform]::new(0,0))
 [void]$artTransforms.Children.Add($p.Flip)
 [void]$artTransforms.Children.Add($p.ArtRotation)
 [void]$artTransforms.Children.Add($p.ArtScale)
 [void]$artTransforms.Children.Add($p.ArtShift)
 $p.Art.RenderTransform=$artTransforms
 $headTransforms=[System.Windows.Media.TransformGroup]::new()
 $p | Add-Member NoteProperty HeadScale ([System.Windows.Media.ScaleTransform]::new(1,1))
 $p | Add-Member NoteProperty HeadRotation ([System.Windows.Media.RotateTransform]::new(0))
 [void]$headTransforms.Children.Add($p.HeadScale)
 [void]$headTransforms.Children.Add($p.HeadRotation)
 $p.HeadGroup.RenderTransform=$headTransforms
  $p.ToyHammer.RenderTransform=[System.Windows.Media.RotateTransform]::new(0)
 foreach($partName in @('EarLeft','EarRight','LegLeft','LegRight')) {
  $part=$p.$partName
  $part.RenderTransform=[System.Windows.Media.RotateTransform]::new(0)
 }
 $p.SpeechPopup.PlacementTarget=$window
 $window.Tag=$p;$window.Left=$x;$window.Top=$y
 $window.Add_MouseLeftButtonDown({param($s,$e)
  $p=$s.Tag;$p.Drag=$true;$p.NavStage='';$p.Mode='drag';$p.VY=0
  $pos=[System.Windows.Forms.Cursor]::Position
  $m=([System.Windows.PresentationSource]::FromVisual($s)).CompositionTarget.TransformFromDevice
  $p.DX=$pos.X*$m.M11-$p.X;$p.DY=$pos.Y*$m.M22-$p.Y
  [void]$s.CaptureMouse();$e.Handled=$true
 })
 $window.Add_MouseMove({param($s,$e)
  $p=$s.Tag;if(!$p.Drag){return}
  $pos=[System.Windows.Forms.Cursor]::Position
  $m=([System.Windows.PresentationSource]::FromVisual($s)).CompositionTarget.TransformFromDevice
  $p.X=$pos.X*$m.M11-$p.DX;$p.Y=$pos.Y*$m.M22-$p.DY
  $s.Left=$p.X;$s.Top=$p.Y
 })
 $window.Add_MouseLeftButtonUp({param($s,$e)
  $p=$s.Tag;if($p.Drag){$p.Drag=$false;$p.Mode='walk';$p.Until=0;$p.VY=0;$s.ReleaseMouseCapture()}
 })
 $window.Add_LostMouseCapture({param($s,$e) $s.Tag.Drag=$false})
 $menu=[System.Windows.Controls.ContextMenu]::new()
 $exit=[System.Windows.Controls.MenuItem]::new()
 $exit.Header='Έξοδος'
 $exit.Add_Click({$script:app.Shutdown()})
 [void]$menu.Items.Add($exit)
 $window.ContextMenu=$menu
 foreach($joint in @('WristLX','WristLY','WristRX','WristRY')){
  $p | Add-Member -NotePropertyName $joint -NotePropertyValue 0.0 -Force
 }
 $script:pets+=,$p;$window.Show()
}
# Fixed-length, 2-bone forward-kinematics chain. The shoulder never leaves the torso.
# The pose angle comes from the existing animation state; elbow bend stays constrained.
# Δισδιάστατη IK 2 οστών: ώμος -> αγκώνας -> παλάμη.
# Στόχος καρπού + λύση δύο κύκλων. Ανεξάρτητος αγκώνας, όχι σταθερό bend ±8°.
# Αποφυγή αδύνατων στόχων με clamp στο [|L1-L2|, L1+L2].
function Update-PetArm($p,[string]$side,[double]$pose,[bool]$profile,[bool]$back){
 $left=($side -eq 'L')
 if($profile){
  if($left){$sx=56.0;$sy=112.0;$neutral=-32.0;$opacity=0.65}
  else{$sx=94.0;$sy=112.0;$neutral=38.0;$opacity=1.0}
 } else {
  if($left){$sx=46.0;$sy=112.0;$neutral=-42.0;$opacity=1.0}
  else{$sx=94.0;$sy=112.0;$neutral=42.0;$opacity=1.0}
 }
 $theta=[math]::Max(-155.0,[math]::Min(155.0,$neutral+0.75*$pose))*[math]::PI/180.0
 $len1=14.0;$len2=10.0
 $reach=23.0
 $jointSide=if($left){-1.0}else{1.0}
 # Το χέρι διπλώνει πιο φυσικά στις αγκαλιές, στα δώρα και στο φαγητό.
 if($p.Mode -in @('hug','pairsleep','story-hug')){$reach=18.0}
 elseif($p.Mode -in @('flower-give','flower-receive','gift-give','gift-receive','eat','duoeat','food-offer')){$reach=19.5}
 elseif($p.Mode -in @('story-sit','story-pc','story-scold','story-apology')){$reach=20.0}
 elseif($p.Mode -in @('walk','pairdance','dance','pairsing')){$reach=22.3}
 # Στο side view το βάθος αλλάζει μόνο opacity, όχι τα οστά.
 $wx=$sx+[math]::Sin($theta)*$reach
 $wy=$sy+[math]::Cos($theta)*$reach
 $vx=$wx-$sx;$vy=$wy-$sy
 $r=[math]::Sqrt($vx*$vx+$vy*$vy)
 $r=[math]::Max([math]::Abs($len1-$len2)+0.05,[math]::Min($len1+$len2-0.02,$r))
 $ux=$vx/$r;$uy=$vy/$r
 $along=($len1*$len1-$len2*$len2+$r*$r)/(2.0*$r)
 $perp=[math]::Sqrt([math]::Max(0.0,$len1*$len1-$along*$along))
 $ex=$sx+$ux*$along-$uy*$perp*$jointSide
 $ey=$sy+$uy*$along+$ux*$perp*$jointSide
 if($left){$upper=$p.ArmLeftUpper;$lower=$p.ArmLeftLower;$upperOutline=$p.ArmLeftUpperOutline;$lowerOutline=$p.ArmLeftLowerOutline;$hand=$p.ArmLeftHand}
 else{$upper=$p.ArmRightUpper;$lower=$p.ArmRightLower;$upperOutline=$p.ArmRightUpperOutline;$lowerOutline=$p.ArmRightLowerOutline;$hand=$p.ArmRightHand}
 foreach($segment in @($upper,$upperOutline)){$segment.X1=$sx;$segment.Y1=$sy;$segment.X2=$ex;$segment.Y2=$ey;$segment.Opacity=$opacity}
 foreach($segment in @($lower,$lowerOutline)){$segment.X1=$ex;$segment.Y1=$ey;$segment.X2=$wx;$segment.Y2=$wy;$segment.Opacity=$opacity}
 [System.Windows.Controls.Canvas]::SetLeft($hand,$wx-$hand.Width*0.5)
 [System.Windows.Controls.Canvas]::SetTop($hand,$wy-$hand.Height*0.5)
 $hand.Opacity=$opacity
 if($left){$p.WristLX=$wx;$p.WristLY=$wy}
 else{$p.WristRX=$wx;$p.WristRY=$wy}
}


# Ορατός χαιρετισμός και για τα δύο αρκουδάκια: το χέρι περνά έξω
# από το περίγραμμα του κεφαλιού, ενώ η παλάμη κινείται απαλά.
# Μικρό χεράκι χαιρετισμού με αναλογίες chibi, στον ίδιο ώμο.
# Δεν επηρεάζει το μέγεθος των χεριών σε άλλες δραστηριότητες.
# Ο χαιρετισμός χρησιμοποιεί τα ίδια μικρά χεράκια με το περπάτημα.
# Δεν υπάρχει πια ξεχωριστός βραχίονας ή παλάμη για τη χειρονομία.

# Utility AI και για ατομικές συνήθειες: όχι ανεξάρτητο ομοιόμορφο ζάρι.
# Χαρακτήρας, ανάγκες, πρόσφατες επιλογές και κατάσταση του άλλου.
# Ανθρωποειδής 2D κινηματική κάτω άκρου: λεκάνη -> γόνατο -> αστράγαλος.
# Τα πόδια πατούν εναλλάξ, με πραγματικό στόχο πατούσας από το gait controller.
# Ο στόχος περιορίζεται πριν τη λύση IK, αποτρέποντας υπερέκταση και αναστροφή γονάτου.
function Update-PetLeg($p,[string]$side,[double]$footX,[double]$footY,[bool]$profile,[bool]$swing) {
 $left=($side -eq 'L')
 $hipX=if($left){60.0}else{80.0}
 if($profile){$hipX=if($left){66.0}else{82.0}}
 $hipY=127.5
 $ankleX=$footX+8.0
 $ankleY=$footY+6.0
 $vx=$ankleX-$hipX;$vy=$ankleY-$hipY
 $distance=[math]::Sqrt($vx*$vx+$vy*$vy)
 $upperLength=13.0;$lowerLength=13.0
 $reach=[math]::Max(4.0,[math]::Min(25.8,$distance))
 if($distance -lt 0.001){$vx=0;$vy=1;$distance=1}
 $ux=$vx/$distance;$uy=$vy/$distance
 $ankleX=$hipX+$ux*$reach;$ankleY=$hipY+$uy*$reach
 $along=($upperLength*$upperLength-$lowerLength*$lowerLength+$reach*$reach)/(2.0*$reach)
 $perp=[math]::Sqrt([math]::Max(0.0,$upperLength*$upperLength-$along*$along))
 # Τα γόνατα διπλώνουν προς τη φορά του βήματος και όχι προς τα πίσω.
 $bend=if($swing){1.0}else{0.65}
 $bendSide=if($left){-1.0}else{1.0}
 $kx=$hipX+$ux*$along-$uy*$perp*$bendSide*$bend
 $ky=$hipY+$uy*$along+$ux*$perp*$bendSide*$bend
 if($left){$u=$p.ThighLeft;$v=$p.ShinLeft;$uo=$p.ThighLeftOutline;$vo=$p.ShinLeftOutline}
 else{$u=$p.ThighRight;$v=$p.ShinRight;$uo=$p.ThighRightOutline;$vo=$p.ShinRightOutline}
 foreach($line in @($u,$uo)){$line.X1=$hipX;$line.Y1=$hipY;$line.X2=$kx;$line.Y2=$ky}
 foreach($line in @($v,$vo)){$line.X1=$kx;$line.Y1=$ky;$line.X2=$ankleX;$line.Y2=$ankleY}
 # Η οπίσθια πλευρά του κορμού αποκρύπτει μέρος του πίσω άκρου.
 $opacity=if($profile -and $left){0.70}else{1.0}
 foreach($line in @($u,$v,$uo,$vo)){$line.Opacity=$opacity}
}

function Choose-SoloMode($p,[double]$now) {
 $weights=[ordered]@{walk=28.0;idle=18.0;think=8.0;eat=5.0;yawn=2.0;wave=3.0;laugh=3.0;dance=3.0;heart=3.0}
 if($p.Name -eq 'Bubu'){$weights['dance']+=5.0;$weights['laugh']+=4.0;$weights['heart']+=4.0;$weights['wave']+=3.0}
 else{$weights['idle']+=9.0;$weights['think']+=7.0;$weights['eat']+=3.0;$weights['heart']+=3.0}
 if($p.Energy -lt 35){$weights['idle']+=22.0;$weights['yawn']+=12.0;$weights['dance']*=0.20}
 if($p.Hunger -gt 60){$weights['eat']+=27.0}
 if($p.AffectionNeed -gt 65){$weights['heart']+=14.0}
 if($p.Stress -gt 50){$weights['think']+=10.0;$weights['dance']*=0.3}
 if($null -ne $p.Partner -and $p.Partner.Mode -notin @('idle','walk','think')){$weights['walk']+=18.0}
 foreach($key in @($weights.Keys)){
  if($key -eq $p.SoloLast){$weights[$key]*=0.08}
  elseif($key -eq $p.SoloPrevious){$weights[$key]*=0.36}
 }
 $total=0.0
 foreach($value in $weights.Values){$total+=[double]$value}
 $ticket=$script:random.NextDouble()*$total
 $result='walk'
 foreach($key in @($weights.Keys)){
  $ticket-=[double]$weights[$key]
  if($ticket -le 0.0){$result=[string]$key;break}
 }
 $p.SoloPrevious=$p.SoloLast;$p.SoloLast=$result;$p.SoloLastAt=$now
 return $result
}
# Μετάβαση μεταξύ διαφορετικών επιπέδων παραθύρων χωρίς τηλεμεταφορά.
# Η πλοήγηση εκτελείται μόνο στην προσέγγιση ενεργού κοινωνικής σκηνής.
function Test-ApproachMode($pet) {
 return ($pet.Mode -in @('rescue','food-run','gift-approach','close-approach','kiss-approach',
  'pair-approach','story-run','story-walk','hammer-run','xmas-approach'))
}
function Find-SupportPlatform($pet) {
 $feet=$pet.Y+150.0
 $best=$null;$bestDelta=12.0
 foreach($r in $script:platforms){
  if($r.R-$r.L -lt 90.0){continue}
  $touch=($pet.X+105.0 -gt $r.L -and $pet.X+35.0 -lt $r.R)
  $d=[math]::Abs($feet-$r.T)
  if($touch -and $d -lt $bestDelta){$best=$r;$bestDelta=$d}
 }
 return $best
}
# Κοινός ελεγκτής συνάντησης: συνυπολογίζει πραγματικές αποστάσεις,
# προσβάσιμο επίπεδο, το ποιος εκτελεί προσέγγιση και την προσωπικότητα.
# Δεν αναζητείται γωνία παραθύρου. Μία αρκούδα εκτελεί αλλαγή επιπέδου τη φορά.
function Get-MeetingTraversal($upper,$lower,[double]$now) {
 $upperApproach=Test-ApproachMode $upper
 $lowerApproach=Test-ApproachMode $lower
 if(!$upperApproach -and !$lowerApproach){return ''}
 if($upper.NavStage -ne ''){return 'jump'}
 if($lower.NavStage -ne ''){return 'climb'}
 $dx=[math]::Abs($upper.X-$lower.X)
 $dy=$lower.Y-$upper.Y
 if($dy -lt 33.0){return ''}
 $upperSurface=Find-SupportPlatform $upper
 $lowerTarget=Find-SupportPlatform $upper
 $canJump=($upperApproach -and $null -ne $upperSurface -and $now -ge $upper.NavRetryAfter)
 $canClimb=($lowerApproach -and $null -ne $lowerTarget -and $now -ge $lower.NavRetryAfter)
 if(!$canJump -and !$canClimb){return ''}
 if(!$canJump){return 'climb'}
 if(!$canClimb){return 'jump'}
 # Οι βαθμολογίες είναι τοπικό Utility AI, όχι μηχανική μάθηση νέων κινήσεων.
 # Παιχνιδιάρικη Bubu: μεγαλύτερη τάση για άλμα.
 # Υπομονετικός Dudu: μεγαλύτερη τάση για αναρρίχηση.
 $jumpScore=52.0-0.060*$dx-0.026*$dy
 $climbScore=47.0-0.024*$dx-0.040*$dy
 if($upper.Name -eq 'Bubu'){$jumpScore+=9.0}
 if($lower.Name -eq 'Dudu'){$climbScore+=8.0}
 if($upper.Energy -lt 30.0){$jumpScore-=16.0}
 if($lower.Energy -lt 30.0){$climbScore-=16.0}
 # Μεγάλη οριζόντια απόσταση: προτιμάται η αναρρίχηση προς την πλατφόρμα.
 if($dx -gt 340.0){$climbScore+=14.0}
 # Αποφυγή μόνιμης προτίμησης του ίδιου τρόπου όταν αποτυγχάνει η προσέγγιση.
 if($upper.NavLastChoice -eq 'jump' -and $now-$upper.NavChoiceAt -lt 12.0){$jumpScore-=17.0}
 if($lower.NavLastChoice -eq 'climb' -and $now-$lower.NavChoiceAt -lt 12.0){$climbScore-=17.0}
 if($jumpScore -ge $climbScore){return 'jump'}
 return 'climb'
}
function Set-LevelNavigation($pet,[string]$stage,$r,[double]$now) {
 $pet.NavStage=$stage
 $pet.NavStart=$now
 $pet.NavHeightY=$pet.Y
 $pet.NavChoiceAt=$now
 if($null -ne $r){
  $pet.NavPlatformL=[double]$r.L
  $pet.NavPlatformR=[double]$r.R
  $pet.NavPlatformTop=[double]$r.T
 }
}
function Update-LevelNavigation($pet,[double]$dt,[double]$now) {
 if($null -eq $pet.Partner -or $pet.Drag -or $script:pairScene -eq ''){
  $pet.NavStage='';$pet.NavVX=0.0;return
 }
 $other=$pet.Partner
 # Μια ενεργή πτήση/αναρρίχηση ολοκληρώνεται ακόμη κι αν αλλάξει
 # προσωρινά η κατάσταση animation στην εξέλιξη του reaction.
 if($pet.NavStage -eq ''){
  if(!(Test-ApproachMode $pet) -or $now -lt $pet.NavRetryAfter){return}
  if([math]::Abs($other.Y-$pet.Y) -lt 33.0){return}
  $upper=if($pet.Y -le $other.Y){$pet}else{$other}
  $lower=if($pet.Y -gt $other.Y){$pet}else{$other}
  $decision=Get-MeetingTraversal $upper $lower $now
  if($decision -eq 'jump' -and $pet.Name -eq $upper.Name){
   $support=Find-SupportPlatform $pet
   if($null -eq $support){return}
   Set-LevelNavigation $pet 'jump-air' $support $now
   $pet.NavLastChoice='jump'
   $pet.Grounded=$false
   $dx=$other.X-$pet.X
   # Πλάγιο άλμα προς τον άλλον όταν υπάρχει οριζόντια απόσταση,
   # αλλιώς σχεδόν κατακόρυφο άλμα προς τα κάτω.
   $pet.NavVX=if([math]::Abs($dx) -gt 125.0){[math]::Sign($dx)*[math]::Min(245.0,[math]::Max(105.0,[math]::Abs($dx)*0.60))}else{0.0}
   $pet.VY=if([math]::Abs($dx) -gt 125.0){-245.0}else{-175.0}
  } elseif($decision -eq 'climb' -and $pet.Name -eq $lower.Name){
   $support=Find-SupportPlatform $other
   if($null -eq $support){return}
   Set-LevelNavigation $pet 'climb-up' $support $now
   $pet.NavLastChoice='climb';$pet.NavVX=0.0;$pet.VY=0.0
  }
 }
 if($pet.NavStage -eq ''){return}
 if($now-$pet.NavStart -gt 13.0){
  $pet.NavStage='';$pet.NavVX=0.0;$pet.NavRetryAfter=$now+2.0;return
 }
 if($pet.NavStage -eq 'jump-air'){
  # Η βαρύτητα και η επαφή με επιφάνειες εκτελούνται στο Move-Pet.
  # Εδώ εφαρμόζεται η οριζόντια συνιστώσα του άλματος και ελαφριά
  # διόρθωση πορείας όσο πλησιάζει το ύψος του συντρόφου.
  $remainingX=$other.X-$pet.X
  if($pet.NavVX -ne 0.0){
   $targetVelocity=[math]::Sign($remainingX)*[math]::Min(245.0,[math]::Max(0.0,([math]::Abs($remainingX)-78.0)*2.0))
   $blend=[math]::Min(1.0,$dt*2.4)
   $pet.NavVX+=(($targetVelocity-$pet.NavVX)*$blend)
   $pet.X+=$pet.NavVX*$dt
  }
  # Η προσγείωση σε ενδιάμεσο παράθυρο τερματίζει το άλμα και
  # επιτρέπει νέα απόφαση AI, αντί να «κολλήσει» στον αέρα.
  if($pet.Grounded -and $now-$pet.NavStart -gt 0.26){
   $pet.NavStage='';$pet.NavVX=0.0;$pet.NavRetryAfter=$now+0.9
  }
 } elseif($pet.NavStage -eq 'climb-up'){
  $targetY=$pet.NavPlatformTop-150.0
  $pet.Y=[math]::Max($targetY,$pet.Y-156.0*$dt)
  $pet.VY=0.0;$pet.Grounded=$false
  # Σταδιακή σύγκλιση στην οριζόντια θέση του άλλου,
  # πάντοτε πάνω από τη διαθέσιμη επιφάνεια.
  $targetX=[math]::Max($pet.NavPlatformL-99.0,[math]::Min($pet.NavPlatformR-45.0,$other.X))
  $dx=$targetX-$pet.X
  if([math]::Abs($dx) -gt 1.0){
   $pet.X+=[math]::Sign($dx)*[math]::Min([math]::Abs($dx),95.0*$dt)
  }
  if($pet.Y -le $targetY+1.0){
   $pet.Y=$targetY;$pet.VY=0.0;$pet.Grounded=$true
   $pet.NavStage='';$pet.NavRetryAfter=$now+1.0
  }
 }
}
# Περιπολία: οι αρκουδίτσες εξερευνούν ΟΛΟ το διαθέσιμο οριζόντιο τμήμα
# κάθε επιφάνειας, χωρίς να υποχρεώνονται να πάνε στην άκρη για άλμα.
# Επιστρέφει το επιτρεπτό διάστημα για το κέντρο στήριξης του χαρακτήρα.
function Get-WalkBounds($p) {
 $min=[double]($script:area.Left+8.0)
 $max=[double]($script:area.Right-150.0)
 $feet=$p.Y+150.0
 $best=$null;$overlap=0.0
 foreach($r in $script:platforms){
  if([math]::Abs($feet-$r.T) -gt 8.0 -or $r.R-$r.L -lt 100.0){continue}
  $ol=[math]::Max(0.0,[math]::Min($p.X+104.0,$r.R)-[math]::Max($p.X+36.0,$r.L))
  if($ol -gt $overlap){$best=$r;$overlap=$ol}
 }
 if($null -ne $best){
  # Λίγο μέρος του sprite μπορεί να προεξέχει: τα πέλματα μένουν στην πλατφόρμα.
  $min=[math]::Max($min,$best.L-37.0)
  $max=[math]::Min($max,$best.R-103.0)
  if($max -lt $min){$min=[math]::Min($min,$p.X);$max=[math]::Max($max,$p.X)}
 }
 return [pscustomobject]@{Min=$min;Max=$max;Platform=($null -ne $best)}
}
function Update-WalkPatrol($p,[double]$dt,[double]$now) {
 if(!$p.Grounded -or $p.NavStage -ne ''){return}
 $bounds=Get-WalkBounds $p
 $lo=[double]$bounds.Min;$hi=[double]$bounds.Max
 if($hi-$lo -lt 18.0){return}
 # Διαδρομή κατά μήκος όλης της επιφάνειας, με μικρό ασφαλές περιθώριο.
 $margin=[math]::Min(18.0,($hi-$lo)*0.10)
 $lo+=$margin;$hi-=$margin
 $needsGoal=($p.WalkGoalUntil -le $now -or $p.WalkGoalX -lt $lo-3.0 -or $p.WalkGoalX -gt $hi+3.0)
 if($needsGoal){
  # Εναλλαγή στόχων κοντά στα δύο άκρα, όχι στο κέντρο της οθόνης.
  $p.WalkGoalX=if($p.Dir -ge 0){$hi}else{$lo}
  $p.WalkGoalUntil=$now+45.0
 }
 $dx=$p.WalkGoalX-$p.X
 if([math]::Abs($dx) -lt 9.0){
  $p.WalkGoalX=if($p.WalkGoalX -gt ($lo+$hi)*0.5){$lo}else{$hi}
  $p.WalkGoalUntil=$now+45.0
  $dx=$p.WalkGoalX-$p.X
 }
 $desiredDir=[int][math]::Sign($dx)
 if($desiredDir -ne 0 -and $desiredDir -ne $p.Dir){$p.Dir=$desiredDir}
 # Ομαλή εκκίνηση και φρενάρισμα στα άκρα της επιφάνειας.
 $targetSpeed=[math]::Min(56.0,[math]::Max(17.0,[math]::Abs($dx)*1.7))
 $alpha=1.0-[math]::Exp(-$dt/0.32)
 $p.PatrolSpeed+=($targetSpeed-$p.PatrolSpeed)*$alpha
 $step=[math]::Min([math]::Abs($dx),$p.PatrolSpeed*$dt)
 $p.X+=$desiredDir*$step
}
function Move-Pet($p,[double]$dt,[double]$now) {
 $frameStartX=[double]$p.X
 if($p.Drag){
  Set-Rotation $p.Art 8
  return
 }
 # Physics: support from the taskbar/work area or the upper edges of other windows.
 $oldFeet=$p.Y+150
 $floor=$script:area.Bottom
 $nextFeet=$oldFeet+$p.VY*$dt+800*$dt*$dt/2
 $standing=$false
 foreach($r in $script:platforms) {
  # During a direct jump, the departure ledge is one-way until the bear is below it.
  if($p.NavStage -eq 'jump-air' -and [math]::Abs($r.T-$p.NavPlatformTop) -lt 2.0 -and $p.Y+150 -lt $p.NavPlatformTop+22.0){continue}
  if($p.X+105 -gt $r.L -and $p.X+35 -lt $r.R -and $r.T -gt $script:area.Top+20) {
   if([math]::Abs($oldFeet-$r.T) -lt 5 -and $p.VY -ge 0) {
    if($r.T -le $floor){$floor=$r.T;$standing=$true}
   }
   elseif($p.VY -ge 0 -and $oldFeet -le $r.T+3 -and $nextFeet -ge $r.T -and $r.T -lt $floor){$floor=$r.T}
  }
 }
 if([math]::Abs($oldFeet-$script:area.Bottom) -lt 5 -and $p.VY -ge 0){$standing=$true}
 
if($p.Mode -eq 'tumble' -and $now -lt $p.Until) {
  # Διακριτές φάσεις: κάθισμα, στήριξη, κύλιση, επαναφορά.
  # Τροχιά κύλισης και περιστροφή μοιράζονται την ίδια πρόοδο.
  $q=[math]::Min(1.0,[math]::Max(0.0,($now-$p.ModeStart)/1.95))
  $travel=0.0;$rise=0.0
  if($q -lt 0.20){
   $u=$q/0.20
   $ease=$u*$u*(3-2*$u)
   $rise=0.0
  } elseif($q -lt 0.82){
   $u=($q-0.20)/0.62
   $travel=$u*$u*(3-2*$u)
   # Γεωμετρική αντιστάθμιση της περιστροφής ως προς το έδαφος.
   # 70px ημιπλάτος, 76px ύψος γύρω από το σημείο περιστροφής.
   $angle=2.0*[math]::PI*$travel
   $c=[math]::Abs([math]::Cos($angle));$sn=[math]::Abs([math]::Sin($angle))
   $extent=73.0*$c+63.0*$sn
   $rise=[math]::Max(0.0,$extent-73.0)
  } else {
   $travel=1.0
   $rise=0.0
  }
  $p.X=$p.TumbleX+$p.TumbleDir*125.0*$travel
  $p.Y=$p.TumbleY-$rise
  $p.VY=0.0
  $standing=$true
 } else {

  if($standing){$p.Y=$floor-150;$p.VY=0}
  else {$p.VY+=800*$dt;$p.Y+=$p.VY*$dt}
  if($p.Y+150 -ge $floor -and $p.VY -ge 0){$p.Y=$floor-150;$p.VY=0;$standing=$true}
 }
 $p.Grounded=$standing
 if(!$script:startupGreetingPending -and $script:pairScene -eq '' -and $now -ge $p.Until -and $p.Mode -ne 'rescue' -and $p.Mode -ne 'cry' -and $p.Mode -notin @('pair-approach','pair-wait','flower-give','flower-receive','pairsing','pairsleep','food-run','food-offer','hammer-run','hammer-flee','kiss-approach','kiss-active','close-approach','story-sit','story-notice','story-pc','story-scold','story-ashamed','story-apology','story-soften','story-run','story-walk','story-photo','story-travel')) {
  if($p.Mode -ne 'walk' -and $p.Mode -ne 'idle') {
   if(Test-PetSpeechDone $p $now){Set-Mode $p 'walk' $now 1.5}else{$p.Until=$now+0.15}
  }
  else {
   # Διατηρούμε το ίδιο reaction μέχρι να τελειώσει και ο διάλογός του.
   if(!(Test-PetSpeechDone $p $now)){
    $p.Until=[math]::Max($p.Until,$now+0.15)
   }else{
    $choice=Choose-SoloMode $p $now
    switch($choice){
     'walk' {Set-Mode $p 'walk' $now (7.5+$script:random.NextDouble()*10.0)}
     'idle' {Set-Mode $p 'idle' $now (4.0+$script:random.NextDouble()*5.0)}
     'think' {Set-Mode $p 'think' $now (3.0+$script:random.NextDouble()*3.0)}
     'eat' {Set-Mode $p 'eat' $now 4.2 'Μμμ, μπισκοτάκι!'}
     'yawn' {
      if($now-$script:lastSleepScene -ge $script:sleepCooldown){Set-Mode $p 'yawn' $now 3.0 'Νυστάζω...'}
      else{Set-Mode $p 'idle' $now 5.0}
     }
     'wave' {Set-Mode $p 'wave' $now 2.8 (Say-Hello $p)}
     'laugh' {Set-Mode $p 'laugh' $now 2.6 'Χα χα χα!'}
     'dance' {Set-Mode $p 'dance' $now 3.8 'Τι ωραία μέρα!'}
     'heart' {Set-Mode $p 'heart' $now 3.0 (Say-Love $p)}
    }
   }
   # Η αλλαγή κατεύθυνσης αποφασίζεται στο φυσικό άκρο της διαδρομής.
  }
 }
 if($script:pairScene -eq '' -and $now -lt $script:soloUntil -and $p.Mode -in @('walk','idle') -and $null -ne $p.Partner){
  # Brief, smooth spatial separation after each shared scene; each pet then explores alone.
  $gap=$p.Partner.X-$p.X
  if([math]::Abs($gap) -lt 260.0){
   $away=if($gap -ge 0){-1.0}else{1.0}
   $room=if($away -lt 0){$p.X-$script:area.Left}else{$script:area.Right-154.0-$p.X}
   if($room -gt 10.0){$p.Dir=[int]$away;$p.X+=$away*[math]::Min(28.0*$dt,$room-8.0)}
  }
 }
 if($p.Mode -eq 'walk' -and $standing){Update-WalkPatrol $p $dt $now}
 if($p.Mode -eq 'hammer-run' -and $null -ne $p.Partner){
  # Bubu pursues Dudu at a finite speed, without jumps or teleportation.
  $delta=$p.Partner.X-$p.X
  if([math]::Abs($delta) -gt 45){
   $p.Dir=[math]::Sign($delta)
   $p.X+=$p.Dir*[math]::Min(132*$dt,[math]::Abs($delta)-45)
  }
 }
 if($p.Mode -eq 'hammer-flee' -and $null -ne $p.Partner){
  # Dudu flees within the work area and reverses smoothly at the screen edge.
  $dx=$p.X-$p.Partner.X
  if([math]::Abs($dx) -lt 230){
   $away=if($dx -ge 0){1}else{-1}
   if(($away -lt 0 -and $p.X -lt $script:area.Left+35) -or
      ($away -gt 0 -and $p.X -gt $script:area.Right-185)){$away=-$away}
   $p.Dir=$away
  }
  $p.X+=$p.Dir*148*$dt
 }
 if($p.Mode -eq 'food-run' -and $null -ne $p.Partner){
  # The panda follows the bear's current position; no teleport and no frame blocking.
  $dxFood=$p.Partner.X-$p.X
  if([math]::Abs($dxFood) -gt 54){
   $p.Dir=[math]::Sign($dxFood)
   $p.X+=$p.Dir*[math]::Min(138*$dt,[math]::Abs($dxFood)-54)
  }
 }
 if($p.Mode -eq 'rescue' -and $null -ne $p.Partner){
  # Αναζήτηση στόχου σε κάθε frame: ο Dudu δεν κολλάει όταν η Bubu αλλάξει θέση.
  $targetX=$p.Partner.X
  $targetY=$p.Partner.Y
  $diffX=$targetX-$p.X
  if([math]::Abs($diffX) -gt 7.0){
   $p.Dir=[math]::Sign($diffX)
   $step=[math]::Min([math]::Abs($diffX),215.0*$dt)
   $p.X+=$p.Dir*$step
  }
 }
 if($p.Mode -eq 'close-approach' -and $null -ne $p.Partner){
  $dxClose=$p.Partner.X-$p.X
  $gapClose=[math]::Abs($dxClose)
  if($gapClose -gt 3.0){
   $p.Dir=[math]::Sign($dxClose)
   $p.X+=$p.Dir*[math]::Min([math]::Max(0.0,($gapClose-96.0)*0.5),118.0*$dt)
  }
 }
 if($p.Mode -in @('pair-approach','kiss-approach') -and $null -ne $p.Partner){
  $delta=$p.Partner.X-$p.X
  if([math]::Abs($delta) -gt 86){$p.Dir=[math]::Sign($delta);$p.X+=$p.Dir*[math]::Min([math]::Abs($delta)-86,125*$dt)}
 }
 if($p.Mode -eq 'gift-approach' -and $standing -and $null -ne $p.Partner){
  $distance=$p.Partner.X-$p.X
  if([math]::Abs($distance) -gt 76){$p.Dir=[math]::Sign($distance);$p.X+=$p.Dir*70*$dt}
 }
 if($p.Mode -in @('hug','pairdance') -and $null -ne $p.Partner){
  # Σταθερή απόσταση στο ζευγάρι, χωρίς να περνά ο ένας μέσα από τον άλλον.
  $desired=if($p.Mode -eq 'hug'){76.0}else{100.0}
  $delta=$p.Partner.X-$p.X
  $gap=[math]::Abs($delta)
  if($gap -gt 3.0 -and [math]::Abs($gap-$desired) -gt 1.5){
   $p.X+=[math]::Sign($delta)*[math]::Sign($gap-$desired)*[math]::Min(60.0*$dt,[math]::Abs($gap-$desired)*0.48)
  }
 }
 if(($p.Mode -in @('duoeat','gift-give','gift-receive','flower-give','flower-receive','pairsleep','pairsing','kiss-active')) -and $standing -and $null -ne $p.Partner){
  $delta=$p.Partner.X-$p.X
  if([math]::Abs($delta) -gt 58){$p.X+=[math]::Sign($delta)*30*$dt}
 }
 if($p.Mode -eq 'xmas-approach'){
  $diff=[double]($script:xmasBubuTargetX-$p.X)
  if([math]::Abs($diff) -gt 3.0){
   $p.Dir=[int][math]::Sign($diff)
   $p.X+=$p.Dir*[math]::Min(108.0*$dt,[math]::Abs($diff)-3.0)
  }
 }
 if($p.Mode -in @('story-run','story-walk') -and $null -ne $p.Partner){
  $dxStory=$p.Partner.X-$p.X
  if([math]::Abs($dxStory) -gt 83){
   $p.Dir=[math]::Sign($dxStory)
   $rate=if($p.Mode -eq 'story-run'){165.0}else{95.0}
   $p.X+=$p.Dir*[math]::Min($rate*$dt,[math]::Abs($dxStory)-83)
  }
 }
 if($p.Mode -eq 'story-travel' -and $null -ne $p.Partner){
  # Σταθερή συγχρονισμένη κίνηση. Αλλαγή κατεύθυνσης μόνο στα όρια της οθόνης.
  $p.Dir=$script:travelDirection
  $p.X+=$script:travelDirection*24.0*$dt
 }
 Update-LevelNavigation $p $dt $now
 if($p.X -lt $script:area.Left-12){$p.X=$script:area.Left-12;$p.Dir=1}
 if($p.X+140 -gt $script:area.Right+12){$p.X=$script:area.Right-128;$p.Dir=-1}
 if($p.Y -lt $script:area.Top){$p.Y=$script:area.Top;$p.VY=0}
 if($p.Y+150 -gt $script:area.Bottom){$p.Y=$script:area.Bottom-150;$p.VY=0}
 # Καταγεγραμμένη μετατόπιση, όχι υποθετική ταχύτητα animation.
 $p.MoveSpeedX=($p.X-$frameStartX)/[math]::Max(0.001,$dt)
 $velocityBlend=1.0-[math]::Exp(-$dt/0.15)
 $p.SmoothSpeedX+=[double](($p.MoveSpeedX-$p.SmoothSpeedX)*$velocityBlend)
 $travelling=([math]::Abs($p.MoveSpeedX) -gt 6.0)
 if($travelling -and $p.NavStage -eq ''){
  $newDir=[int][math]::Sign($p.MoveSpeedX)
  if($newDir -ne 0 -and $newDir -ne $p.Dir -and $p.Mode -notin @('hug','pairdance','kiss-active')){$p.Dir=$newDir}
 }
 if($p.FacingDir -ne $p.Dir){
  $p.TurnFrom=$p.FacingDir
  $p.FacingDir=$p.Dir
  $p.TurnUntil=$now+0.24
 }
 $p.Anim+=$dt
 $t=$now-$p.ModeStart
 $isRunning=($p.Mode -in @('rescue','food-run','hammer-run','hammer-flee','story-run'))
 $locomotionMode=($p.Mode -in @('walk','rescue','food-run','hammer-run','hammer-flee','story-run','story-walk','story-travel','gift-approach','pair-approach','close-approach','kiss-approach','xmas-approach','story-walk'))
 $walk=($locomotionMode -and $standing -and [math]::Abs($p.MoveSpeedX) -gt 3.0)
 # Η φάση του βήματος αυξάνει ανά ΔΙΑΝΥΘΕΙΣΑ απόσταση, όχι ανά χρόνο.
 # Έτσι τα πόδια σταματούν όταν ο χαρακτήρας σταματά, χωρίς moonwalk.
 if($walk){$p.GaitPhase+=([math]::Abs($p.MoveSpeedX)*$dt)*([math]::PI*2.0/48.0)}
 $phase=$p.GaitPhase
 $p.StrideScale=[math]::Min(1.0,[math]::Abs($p.MoveSpeedX)/62.0)
 $turning=($now -lt $p.TurnUntil)

 $sidePose=((($p.LookSide -gt 0.5) -and $p.Mode -in @('idle','think')) -or $walk -or $p.Mode -in @('rescue','tumble','hug','pairdance','food-run','hammer-run','hammer-flee','gift-approach','flower-give','flower-receive','kiss-approach','kiss-active','close-approach','xmas-approach','story-travel','story-run','story-walk')) -and !$turning
 # Every frame recomputes the attachment points. The head covers the arm roots,
 # the belly covers the upper legs. Only small paws remain visible below it.
 if($sidePose){
  $p.LegLeft.Width=13;$p.LegLeft.Height=14;$p.LegLeft.Opacity=0.55
  $p.LegRight.Width=19;$p.LegRight.Height=18;$p.LegRight.Opacity=1.0
  [System.Windows.Controls.Panel]::SetZIndex($p.LegLeft,-2)
  [System.Windows.Controls.Panel]::SetZIndex($p.LegRight,-2)
  [System.Windows.Controls.Canvas]::SetLeft($p.LegLeft,61)
  [System.Windows.Controls.Canvas]::SetTop($p.LegLeft,136)
  [System.Windows.Controls.Canvas]::SetLeft($p.LegRight,80)
  [System.Windows.Controls.Canvas]::SetTop($p.LegRight,136)
 } else {
  $p.LegLeft.Width=16;$p.LegLeft.Height=16;$p.LegLeft.Opacity=1.0
  $p.LegRight.Width=16;$p.LegRight.Height=16;$p.LegRight.Opacity=1.0
  [System.Windows.Controls.Panel]::SetZIndex($p.LegLeft,-2)
  [System.Windows.Controls.Panel]::SetZIndex($p.LegRight,-2)
  [System.Windows.Controls.Canvas]::SetLeft($p.LegLeft,54)
  [System.Windows.Controls.Canvas]::SetTop($p.LegLeft,136)
  [System.Windows.Controls.Canvas]::SetLeft($p.LegRight,74)
  [System.Windows.Controls.Canvas]::SetTop($p.LegRight,136)
 }
 $leg1=0.0;$leg2=0.0;$arm1=0.0;$arm2=0.0
 $bodyRot=0.0;$bob=0.0;$bodyScaleX=1.0;$bodyScaleY=1.0;$headRot=0.0
 $earL=0.0;$earR=0.0
 if($walk){
  # Contact -> toe-off -> swing -> heel strike, opposite cycles for each paw.
  $stride=[math]::Sin($phase)*$p.StrideScale
  $leftAir=[math]::Max(0,[math]::Sin($phase))*$p.StrideScale
  $rightAir=[math]::Max(0,-[math]::Sin($phase))*$p.StrideScale
  $sideWalk=($sidePose -or $isRunning)
  if($sideWalk){
   # Profile walk: one visible front leg and one lighter back leg, offset clearly.
   $leg1=7*$stride;$leg2=-8*$stride
   $arm1=-11*$stride;$arm2=12*$stride
   $bodyRot=1.1*$p.StrideScale*[math]::Sin($phase)
   $headRot=-2.0*$p.StrideScale*[math]::Sin($phase)
   $bob=-1.3*$p.StrideScale*[math]::Abs([math]::Sin($phase))
   $bodyScaleY=1.0+0.006*[math]::Cos(2*$phase)
   $earL=3*[math]::Sin($phase+0.4);$earR=-3*[math]::Sin($phase-0.4)
   [System.Windows.Controls.Canvas]::SetTop($p.LegLeft,136-5.5*$leftAir)
   [System.Windows.Controls.Canvas]::SetTop($p.LegRight,136-5.5*$rightAir)
   [System.Windows.Controls.Canvas]::SetLeft($p.LegLeft,61+1.8*$stride)
   [System.Windows.Controls.Canvas]::SetLeft($p.LegRight,80-3.0*$stride)
  } else {
   # Front walk: paws mostly move up/down, not wide sideways sliding.
   $leg1=4*$stride;$leg2=-4*$stride
   $arm1=-1.8*$stride;$arm2=1.8*$stride
   $bodyRot=1.0*[math]::Sin($phase)
   $headRot=-2.2*[math]::Sin($phase)
   $bob=-1.5*[math]::Abs([math]::Sin($phase))
   $bodyScaleY=1.0+0.008*[math]::Cos(2*$phase)
   $earL=4*[math]::Sin($phase+0.4);$earR=-4*[math]::Sin($phase-0.4)
   [System.Windows.Controls.Canvas]::SetTop($p.LegLeft,136-5.5*$leftAir)
   [System.Windows.Controls.Canvas]::SetTop($p.LegRight,136-5.5*$rightAir)
   [System.Windows.Controls.Canvas]::SetLeft($p.LegLeft,54+0.8*$stride)
   [System.Windows.Controls.Canvas]::SetLeft($p.LegRight,74-0.8*$stride)
  }
  # Η πατούσα διατηρεί σταθερό X ως προς την οθόνη στη φάση στήριξης.
  # Στη φάση μεταφοράς κινείται με μικρή καμπύλη και ξαναπατά.
  foreach($which in @('L','R')){
   $swing=if($which -eq 'L'){([math]::Sin($phase) -gt 0.0)}else{([math]::Sin($phase) -lt 0.0)}
   $foot=if($which -eq 'L'){$p.LegLeft}else{$p.LegRight}
   $baseX=if($sidePose){if($which -eq 'L'){61.0}else{80.0}}else{if($which -eq 'L'){54.0}else{74.0}}
   $worldAnchor=if($which -eq 'L'){$p.FootLWorld}else{$p.FootRWorld}
   $planted=if($which -eq 'L'){$p.FootLPlanted}else{$p.FootRPlanted}
   if(!$swing -and $standing){
    if(!$planted){$worldAnchor=$p.X+$baseX;$planted=$true}
    $local=$worldAnchor-$p.X
    # Αποφυγή μη φυσικής υπερέκτασης όταν αλλάζει ξαφνικά η ταχύτητα.
    if([math]::Abs($local-$baseX) -gt 8.0){$worldAnchor=$p.X+$baseX;$local=$baseX}
    [System.Windows.Controls.Canvas]::SetLeft($foot,$local)
   }else{$planted=$false}
   if($which -eq 'L'){$p.FootLPlanted=$planted;$p.FootLWorld=$worldAnchor}
   else{$p.FootRPlanted=$planted;$p.FootRWorld=$worldAnchor}
  }
 } elseif($p.Mode -eq 'food-run') {
  $arm1=-$leg1*1.15;$arm2=-$leg2*1.15
 } elseif($p.Mode -eq 'food-offer') {
  $arm1=-80+[math]::Sin($t*3)*7;$arm2=15
  $headRot=[math]::Sin($t*2.8)*3
 } elseif($p.Mode -eq 'eat') {
  $arm1=-95+[math]::Sin($t*9)*16
  $arm2=8
  $bob=[math]::Sin($t*9)*0.9
 } elseif($p.Mode -eq 'cry') {
  $arm1=-55;$arm2=55
  $bodyRot=[math]::Sin($t*13)*6
  $bob=[math]::Abs([math]::Sin($t*13))*2
 } elseif($p.Mode -eq 'tumble') {
  # Καρέ με αντίστοιχη ανατομική πρόθεση, όχι ακαριαία περιστροφή.
  $q=[math]::Min(1.0,[math]::Max(0.0,$t/1.95))
  if($q -lt 0.20){
   $u=$q/0.20;$e=$u*$u*(3-2*$u)
   $bodyScaleY=1.0-0.25*$e;$bodyScaleX=1.0+0.06*$e
   $bob=6.0*$e
   $arm1=85*$e;$arm2=-85*$e
   $leg1=32*$e;$leg2=-32*$e
   $headRot=24*$e
  } elseif($q -lt 0.82){
   $u=($q-0.20)/0.62
   $e=$u*$u*(3-2*$u)
   $bodyRot=$p.TumbleDir*360.0*$e
   $tuck=[math]::Sin([math]::PI*$e)
   $bodyScaleX=0.92-0.08*$tuck
   $bodyScaleY=0.84-0.07*$tuck
   $arm1=90-72*$tuck;$arm2=-90+72*$tuck
   $leg1=38+36*$tuck;$leg2=-38-36*$tuck
   $headRot=18.0*(1-$tuck)
   $earL=9*$tuck;$earR=-9*$tuck
   $bob=0.0
  } else {
   $u=($q-0.82)/0.18;$e=$u*$u*(3-2*$u)
   $bodyRot=$p.TumbleDir*360.0
   $bodyScaleX=0.92+0.08*$e
   $bodyScaleY=0.84+0.16*$e
   $arm1=80*(1-$e);$arm2=-80*(1-$e)
   $leg1=32*(1-$e);$leg2=-32*(1-$e)
   $headRot=18*(1-$e)
   $bob=6*(1-$e)
  }
 } elseif($p.Mode -eq 'dance') {
  $leg1=[math]::Sin($t*11)*31;$leg2=-$leg1
  # Τα χέρια απλώνονται προς τα έξω, όχι προς την κοιλιά.
  # Οι γωνίες περνούν από το IK των δύο αρθρώσεων και παραμένουν ορατές.
  $arm1=-78.0+13.0*[math]::Sin($t*8.0)
  $arm2=78.0-13.0*[math]::Sin($t*8.0+0.6)
  $bob=-[math]::Abs([math]::Sin($t*11))*10
  $bodyRot=[math]::Sin($t*5.5)*12;$headRot=-$bodyRot*0.6
  $earL=[math]::Sin($t*11)*22;$earR=-$earL
 } elseif($p.Mode -eq 'pairdance') {
  # Συγχρονισμένος χορός: ο ένας σηκώνει το πόδι όταν ο άλλος πατά.
  $phaseShift=if($p.Name -eq 'Bubu'){0}else{[math]::PI}
  $beat=[math]::Sin($t*7.5+$phaseShift)
  $leg1=22*$beat;$leg2=-22*$beat
  $arm1=-90+17*[math]::Sin($t*7.5);$arm2=90+17*[math]::Sin($t*7.5)
  $bob=-[math]::Abs($beat)*5
  $bodyRot=5*[math]::Sin($t*3.75+$phaseShift);$headRot=-$bodyRot*0.55
  $earL=7*[math]::Sin($t*7.5);$earR=-$earL
 } elseif($p.Mode -eq 'kiss-approach') {
  $leg1=11*[math]::Sin($t*11);$leg2=-$leg1
  $arm1=-16;$arm2=17
  $bob=-[math]::Abs([math]::Sin($t*11))*2
  $headRot=4*[math]::Sin($t*3)
 } elseif($p.Mode -eq 'kiss-active') {
  $u=[math]::Min(1.0,$t/0.55)
  $headRot=if($p.Dir -gt 0){-9*$u}else{9*$u}
  $bodyRot=if($p.Dir -gt 0){3*$u}else{-3*$u}
  $arm1=-41+3*[math]::Sin($t*6)
  $arm2=42-3*[math]::Sin($t*6)
  $bob=-2*[math]::Sin([math]::PI*[math]::Min(1.0,$t/3.0))
 } elseif($p.Mode -eq 'hug') {
  # Χέρια απλωμένα: και οι δύο καρποί αγκαλιάζουν τον απέναντι.
  $phaseH=[math]::Sin($t*3.8)
  $arm1=-125+9*$phaseH;$arm2=125-9*$phaseH
  $leg1=3*$phaseH;$leg2=-3*$phaseH
  $bob=-1.5*[math]::Abs($phaseH)
  $bodyRot=1.5*[math]::Sin($t*2.3)
  $headRot=if($p.Dir -gt 0){5}else{-5}
  $earL=3*[math]::Sin($t*3.8);$earR=-$earL
 } elseif($p.Mode -eq 'duoeat') {
  $arm1=-88+[math]::Sin($t*9)*13
  $arm2=18+[math]::Sin($t*4)*6
  $bob=[math]::Sin($t*9)*1.2
  $headRot=[math]::Sin($t*7)*3
  $earL=[math]::Sin($t*6)*5;$earR=-$earL
 } elseif($p.Mode -eq 'close-approach') {
  $leg1=16*[math]::Sin($t*10);$leg2=-$leg1
  $arm1=-4*[math]::Sin($t*10);$arm2=-$arm1
  $bob=-1.6*[math]::Abs([math]::Sin($t*10))
  $headRot=2.0*[math]::Sin($t*3)
 } elseif($p.Mode -eq 'pair-approach') {
  $leg1=34*[math]::Sin($t*14);$leg2=-$leg1
  $arm1=-$leg1*0.65;$arm2=-$leg2*0.65
  $bob=[math]::Abs([math]::Sin($t*14))*2
  $headRot=4*[math]::Sin($t*3)
 } elseif($p.Mode -eq 'pair-wait') {
  $arm1=-12;$arm2=12;$headRot=6*[math]::Sin($t*2)
 } elseif($p.Mode -eq 'flower-give') {
  $arm1=-78;$arm2=75;$headRot=5*[math]::Sin($t*2.5)
  $bodyRot=3*[math]::Sin($t*3)
 } elseif($p.Mode -eq 'flower-receive') {
  $arm1=-45+[math]::Sin($t*5)*9;$arm2=43
  $headRot=5*[math]::Sin($t*3);$bob=[math]::Sin($t*3)*1.5
 } elseif($p.Mode -eq 'pairsleep') {
  $bodyRot=if($p.Name -eq 'Bubu'){8}else{-8}
  $headRot=if($p.Name -eq 'Bubu'){11}else{-11}
  $arm1=if($p.Name -eq 'Bubu'){18}else{-18};$arm2=if($p.Name -eq 'Bubu'){-46}else{46};$bob=[math]::Sin($t*2.2)*1.2
 } elseif($p.Mode -eq 'pairsing') {
  $headRot=[math]::Sin($t*4.3)*9;$bob=-[math]::Abs([math]::Sin($t*4.3))*4
  $arm1=-30+[math]::Sin($t*5)*12;$arm2=30-[math]::Sin($t*5)*12
  $earL=[math]::Sin($t*4.3)*11;$earR=-$earL
 } elseif($p.Mode -eq 'gift-approach') {
  $leg1=31*[math]::Sin($t*14);$leg2=-$leg1
  $arm1=-$leg1*0.6;$arm2=-$leg2*0.6
  $headRot=4*[math]::Sin($t*3)
 } elseif($p.Mode -eq 'gift-wait') {
  $arm1=-15;$arm2=15;$headRot=6*[math]::Sin($t*2)
 } elseif($p.Mode -eq 'gift-give') {
  $arm1=if($p.Dir -gt 0){-60}else{60}
  $arm2=if($p.Dir -gt 0){70}else{-70}
  $headRot=[math]::Sin($t*2.4)*7
  $earL=4*[math]::Sin($t*3);$earR=-$earL
  $bob=1.5*[math]::Sin($t*3)
 } elseif($p.Mode -eq 'gift-receive') {
  $arm1=-42+[math]::Sin($t*5)*12
  $arm2=38-[math]::Sin($t*5)*12
  $headRot=[math]::Sin($t*4)*6
  $bob=2*[math]::Sin($t*5)
 } elseif($p.Mode -eq 'xmas-decorate') {
  $arm1=-65+14*[math]::Sin($t*3.7);$arm2=75-12*[math]::Sin($t*3.7)
  $headRot=-5+4*[math]::Sin($t*1.7)
 } elseif($p.Mode -eq 'xmas-tangled') {
  $arm1=-56+8*[math]::Sin($t*7);$arm2=57-8*[math]::Sin($t*7)
  $headRot=-12;$bodyRot=4*[math]::Sin($t*4.2)
 } elseif($p.Mode -eq 'xmas-star') {
  $arm1=-28;$arm2=119+8*[math]::Sin($t*3)
  $headRot=-12
 } elseif($p.Mode -eq 'xmas-plug') {
  $arm1=-32;$arm2=78-9*[math]::Sin($t*2.7)
  $headRot=-5
 } elseif($p.Mode -eq 'xmas-look-up') {
  $arm1=-40;$arm2=40
  $headRot=-13;$bodyRot=3*[math]::Sin($t*2.1)
 } elseif($p.Mode -eq 'xmas-laugh') {
  $bob=-6*[math]::Abs([math]::Sin($t*10))
  $arm1=-60+10*[math]::Sin($t*6);$arm2=65-9*[math]::Sin($t*6)
  $headRot=7*[math]::Sin($t*8)
 } elseif($p.Mode -eq 'story-sit') {
  $bodyScaleY=0.88;$bob=5.0
  $arm1=-50+10*[math]::Sin($t*6.0);$arm2=18
  $leg1=12;$leg2=-12
  $headRot=5*[math]::Sin($t*2.1)
 } elseif($p.Mode -eq 'story-pc') {
  $bodyScaleY=0.92;$bob=4.0
  $arm1=-55+7*[math]::Sin($t*9);$arm2=45+7*[math]::Cos($t*9)
  $headRot=4*[math]::Sin($t*1.4)
 } elseif($p.Mode -eq 'story-notice') {
  $arm1=-18;$arm2=30;$headRot=-9
 } elseif($p.Mode -eq 'story-scold') {
  $arm1=-45;$arm2=100+15*[math]::Sin($t*7)
  $headRot=9*[math]::Sin($t*6);$bodyRot=3*[math]::Sin($t*5)
 } elseif($p.Mode -eq 'story-ashamed') {
  $arm1=32;$arm2=-38;$headRot=15;$bodyScaleY=0.95
 } elseif($p.Mode -eq 'story-apology') {
  $arm1=-35;$arm2=35;$headRot=16;$bodyScaleY=0.94
 } elseif($p.Mode -eq 'story-soften') {
  $arm1=-18;$arm2=18;$headRot=-5;$bob=[math]::Sin($t*2)*1.2
 } elseif($p.Mode -in @('story-run','story-walk','story-travel')) {
  $speed=if($p.Mode -eq 'story-run'){12.0}else{7.0}
  $leg1=13*[math]::Sin($t*$speed);$leg2=-$leg1
  $arm1=-14*[math]::Sin($t*$speed);$arm2=-$arm1
  $bob=-2.2*[math]::Abs([math]::Sin($t*$speed))
  $headRot=3*[math]::Sin($t*$speed)
 } elseif($p.Mode -eq 'story-photo') {
  $arm1=-70;$arm2=92;$headRot=4*[math]::Sin($t*2)
  $bob=-1.5*[math]::Abs([math]::Sin($t*3))
 } elseif($p.Mode -eq 'shy') {
  $headRot=15;$arm1=-70;$arm2=65
  $bodyRot=5*[math]::Sin($t*2)
 } elseif($p.Mode -eq 'think') {
  $headRot=-12;$arm2=-75
 } elseif($p.Mode -eq 'surprise') {
  $headRot=-10;$bodyScaleY=1.07
  $arm1=-55;$arm2=55
 } elseif($p.Mode -eq 'wave') {
  # Ορατός χαιρετισμός: και τα δύο κοντά χεράκια έξω από τον κορμό.
  $arm1=-44.0+10.0*[math]::Sin($t*3.2)
  $arm2=44.0-10.0*[math]::Sin($t*3.2+0.4)
  $bodyRot=[math]::Sin($t*2.0)*1.5
 } elseif($p.Mode -eq 'laugh') {
  $bob=[math]::Abs([math]::Sin($t*15))*8
  $arm1=-35;$arm2=35
 } elseif($p.Mode -eq 'sleep') {
  $bodyRot=-7;$bob=[math]::Sin($t*2)*1.5
 } elseif($p.Mode -eq 'heart') {
  $arm1=-45;$arm2=45;$bob=[math]::Sin($t*5)*3
 } elseif($p.Mode -eq 'jump' -or !$standing) {
  $leg1=-20;$leg2=20;$arm1=-65;$arm2=65
  $bodyRot=[math]::Sin($t*4)*10
 }
 if($p.Mode -eq 'idle' -or $p.Mode -eq 'sleep') {
  $breath=[math]::Sin($now*2.7)
  $bodyScaleX=1.0+0.013*$breath
  $bodyScaleY=1.0-0.015*$breath
  $headRot=[math]::Sin($now*1.6)*2.2
  $earL=[math]::Sin($now*2.8)*4
  $earR=-$earL
  $arm1=[math]::Sin($now*2.2)*3
  $arm2=-$arm1
  $leg1=[math]::Sin($now*2.0)*2
  $leg2=-$leg1
 }
 if($p.NavStage -eq 'climb-up'){
  $grab=[math]::Sin($now*10.0)
  $arm1=-85.0+12.0*$grab
  $arm2=85.0+12.0*$grab
  $leg1=22.0*$grab;$leg2=-22.0*$grab
  $headRot=-7.0
  $bob=0.0
 } elseif($p.NavStage -eq 'jump-air'){
  $arm1=-54.0;$arm2=54.0
  $leg1=-17.0;$leg2=17.0
 }
 if($p.Mode -eq 'cry') { $headRot=[math]::Sin($t*12)*7; $earL=-13;$earR=13 }
 if($p.Mode -in @('laugh','xmas-laugh')) { $headRot=[math]::Sin($t*10)*9; $earL=-8;$earR=8 }
 if($p.Mode -eq 'eat') { $headRot=[math]::Sin($t*9)*3; $earL=[math]::Sin($t*6)*5;$earR=-$earL }
 if($p.Mode -eq 'yawn') { $headRot=-8; $earL=-10;$earR=10 }
 # Μικρή αντιστάθμιση αδράνειας: ο κορμός γέρνει στη φορά κίνησης
 # και το κεφάλι σταθεροποιείται αντίθετα. Περιορίζεται για να μην
 # παραμορφώνονται οι ζωγραφισμένοι χαρακτήρες.
 if($walk){
  $lean=[math]::Max(-2.8,[math]::Min(2.8,$p.MoveSpeedX*0.018))
  $bodyRot+=$lean
  $headRot-=$lean*0.65
 }
 # Ενιαίος locomotion layer: το βάδισμα έχει προτεραιότητα από χρονικές
 # ταλαντώσεις των επιμέρους reactions. Έτσι δεν χάνεται η φάση στήριξης.
 if($walk -and $p.NavStage -eq ''){
  $stride=[math]::Sin($phase)*$p.StrideScale
  $leg1=11.0*$stride;$leg2=-11.0*$stride
  $arm1=-15.0*$stride;$arm2=15.0*$stride
  if($isRunning){$leg1*=1.25;$leg2*=1.25;$arm1*=1.35;$arm2*=1.35}
  $bodyRot=1.6*[math]::Sin($phase)+[math]::Max(-3.0,[math]::Min(3.0,$p.SmoothSpeedX*0.015))
  $headRot=-0.65*$bodyRot+1.4*[math]::Sin(0.5*$phase)
  $bob=-1.6*[math]::Abs([math]::Sin($phase))
  $earL=3.5*[math]::Sin($phase+0.4);$earR=-3.5*[math]::Sin($phase-0.4)
  $bodyScaleY=1.0+0.006*[math]::Cos(2.0*$phase)
 }
 # Smooth transitions between emotions and interaction poses, not their ongoing motion.
 # Exponential blend gives stable results across different refresh rates.
 if($p.Mode -ne 'tumble'){
  $blend=1.0-[math]::Exp(-$dt/0.095)
  $p.SmoothArmL+=($arm1-$p.SmoothArmL)*$blend
  $p.SmoothArmR+=($arm2-$p.SmoothArmR)*$blend
  $p.SmoothHead+=($headRot-$p.SmoothHead)*$blend
  $p.SmoothBody+=($bodyRot-$p.SmoothBody)*$blend
  $arm1=$p.SmoothArmL;$arm2=$p.SmoothArmR
  $headRot=$p.SmoothHead;$bodyRot=$p.SmoothBody
 }else{
  $p.SmoothArmL=$arm1;$p.SmoothArmR=$arm2
  $p.SmoothHead=$headRot;$p.SmoothBody=0.0
 }
 if(!$walk){$p.FootLPlanted=$false;$p.FootRPlanted=$false}
 Set-Rotation $p.EarLeft $earL
 Set-Rotation $p.EarRight $earR
 # Κάθε πόδι αποτελείται πλέον από δύο οστά και πέλμα (όχι μόνο μια έλλειψη).
 $leftFootX=[System.Windows.Controls.Canvas]::GetLeft($p.LegLeft)
 $rightFootX=[System.Windows.Controls.Canvas]::GetLeft($p.LegRight)
 $leftFootY=[System.Windows.Controls.Canvas]::GetTop($p.LegLeft)
 $rightFootY=[System.Windows.Controls.Canvas]::GetTop($p.LegRight)
 if(!$walk){
  # Επαναφορά πέλματος μετά από δραστηριότητα, χωρίς παλαιά φυτεμένη θέση.
  $leftBase=if($sidePose){61.0}else{54.0}
  $rightBase=if($sidePose){80.0}else{74.0}
  $leftFootX=$leftBase;$rightFootX=$rightBase
  $leftFootY=136.0;$rightFootY=136.0
  if(!$standing){$leftFootY=133.0;$rightFootY=133.0}
  [System.Windows.Controls.Canvas]::SetLeft($p.LegLeft,$leftFootX)
  [System.Windows.Controls.Canvas]::SetLeft($p.LegRight,$rightFootX)
  [System.Windows.Controls.Canvas]::SetTop($p.LegLeft,$leftFootY)
  [System.Windows.Controls.Canvas]::SetTop($p.LegRight,$rightFootY)
 }
 Update-PetLeg $p 'L' $leftFootX $leftFootY $sidePose ($walk -and [math]::Sin($phase) -gt 0)
 Update-PetLeg $p 'R' $rightFootX $rightFootY $sidePose ($walk -and [math]::Sin($phase) -lt 0)
 Set-Rotation $p.LegLeft $leg1
 Set-Rotation $p.LegRight $leg2
 # FK updates both joint chains from anchored shoulders, with no temporary WPF allocations.
 Update-PetArm $p 'L' $arm1 $sidePose $false
 Update-PetArm $p 'R' $arm2 $sidePose $false
 $isHammer=($p.Name -eq 'Bubu' -and $p.Mode -eq 'hammer-run')
 $p.ToyHammer.Visibility=if($isHammer){'Visible'}else{'Collapsed'}
 if($isHammer){
  $swing=[math]::Sin($t*9.5)
  # Hammer/hand move together on a short, playful swing cycle.
  Update-PetArm $p 'R' (-120+23*$swing) $sidePose $false
  $p.ToyHammer.RenderTransform.Angle=-18+27*$swing
  [System.Windows.Controls.Canvas]::SetTop($p.ToyHammer,24+3*[math]::Abs($swing))
 }

 # Διατηρούμε κανονικές αναλογίες και στα δύο χεράκια σε όλες τις κινήσεις.
  foreach($line in @($p.ArmLeftUpper,$p.ArmRightUpper)){$line.StrokeThickness=15.0}
  foreach($line in @($p.ArmLeftLower,$p.ArmRightLower)){$line.StrokeThickness=12.5}
  foreach($line in @($p.ArmLeftUpperOutline,$p.ArmRightUpperOutline)){$line.StrokeThickness=18.0}
  foreach($line in @($p.ArmLeftLowerOutline,$p.ArmRightLowerOutline)){$line.StrokeThickness=15.5}
  foreach($hand in @($p.ArmLeftHand,$p.ArmRightHand)){$hand.Width=10.0;$hand.Height=8.0;$hand.RadiusX=4.0;$hand.RadiusY=4.0}
 # Τα χέρια του χορού («Τι ωραία μέρα!»), του χαιρετισμού και της
 # αγκαλιάς σχεδιάζονται μπροστά από τον κορμό (Z=2). Το κεφάλι (Z=3)
 # παραμένει επάνω από αυτά λόγω μεταγενέστερης σειράς σχεδίασης στο XAML.
 $armsFront=($p.Mode -in @('hug','pairdance','dance','wave'))
 $zArm=if($armsFront){3}else{1}
 foreach($piece in @($p.ArmLeftUpperOutline,$p.ArmLeftLowerOutline,$p.ArmLeftUpper,$p.ArmLeftLower,$p.ArmLeftHand,$p.ArmRightUpperOutline,$p.ArmRightLowerOutline,$p.ArmRightUpper,$p.ArmRightLower,$p.ArmRightHand)){
  [System.Windows.Controls.Panel]::SetZIndex($piece,$zArm)
 }
 # Εφαρμογή μετά τη γενική σειρά σχεδίασης, ώστε να μη χάνεται το χεράκι.
 # Living eyes: blinking (short eyelid closure) and autonomous gaze shifts.
 if($now -ge $p.NextBlink) {
  $p.BlinkTime=$now
  $p.NextBlink=$now+2.2+$script:random.NextDouble()*4.4
 }
 if($now -ge $p.NextGaze) {
  $p.Gaze=($script:random.NextDouble()*2.0-1.0)*3.5
  $p.NextGaze=$now+0.9+$script:random.NextDouble()*2.5
 }
 $blink=($now-$p.BlinkTime -ge 0 -and $now-$p.BlinkTime -lt 0.15)
 $closed=$p.Mode -in @('yawn','sleep','pairsleep','cry','kiss-active') -or $blink
 # Face direction is a separate drawing, not a stretched two-eye face.
 # Walk/run/tumble show a true one-eye side muzzle; idle alternates between views.
 if($now -gt $p.NextLook) {
  $p.LookSide=if($script:random.Next(3) -gt 0){1.0}else{0.0}
  $p.NextLook=$now+4.0+$script:random.NextDouble()*6.0
 }
 # Occasionally turn around when idle. Keep the full front face during interactions.
 if($now -ge $p.NextBack){
  $p.BackUntil=$now+1.8
  $p.NextBack=$now+22.0+$script:random.NextDouble()*16.0
 }
 $back=($p.Mode -eq 'idle' -and $now -lt $p.BackUntil)
 $side=($sidePose -and !$back -and !$turning)
 $p.FrontHeadView.Visibility=if($side -or $back){'Collapsed'}else{'Visible'}
 $p.ProfileHeadView.Visibility=if($side){'Visible'}else{'Collapsed'}
 $p.BackHeadView.Visibility=if($back){'Visible'}else{'Collapsed'}
 $p.BubuBow.Visibility=if($p.Name -eq 'Bubu' -and !$back -and !$side){'Visible'}else{'Collapsed'}
 $p.BubuBowSide.Visibility=if($p.Name -eq 'Bubu' -and $side){'Visible'}else{'Collapsed'}
 $p.FrontBody.Visibility=if($side -or $back){'Collapsed'}else{'Visible'}
 $p.ProfileBody.Visibility=if($side){'Visible'}else{'Collapsed'}
 $p.BackBody.Visibility=if($back){'Visible'}else{'Collapsed'}
 # Ουρά: διακριτή κίνηση με μικρή καθυστέρηση από τη λεκάνη.
 $tailAngle=if($walk){5.0*[math]::Sin($phase-0.6)}else{2.0*[math]::Sin($now*1.7)}
 Set-Rotation $p.TailSide $tailAngle
 Set-Rotation $p.TailBack (-$tailAngle)
 [System.Windows.Controls.Canvas]::SetLeft($p.ProfileEye,91.0+[math]::Max(-1.5,[math]::Min(1.5,$p.Gaze*0.35)))
 $p.ProfileEye.Height=if($closed){2}else{10}
 $p.ProfileMouth.Visibility=if($p.Mode -in @('laugh','xmas-laugh','xmas-look-up','xmas-tangled','yawn','surprise','eat','duoeat','gift-receive','pairsing')){'Visible'}else{'Collapsed'}
 $p.ProfileSmile.Visibility=if($p.Mode -eq 'cry'){'Collapsed'}else{'Visible'}
 # Update cached transforms (no new objects allocated per frame).
 $p.HeadScale.ScaleX=1.0
 $p.HeadRotation.Angle=$headRot
 # Σκιά επαφής: μειώνεται στην πτήση, σταθεροποιείται όταν τα πόδια πατούν.
 if($standing){$p.Shadow.Opacity=0.80}else{$p.Shadow.Opacity=0.28}
 # RenderTransformOrigin is set once below for each state.
 # Στο γύρισμα προβάλλεται η μπροστινή όψη και η αντιστροφή
 # γίνεται σταδιακά, ώστε να μη γυρίζει στιγμιαία το πρόσωπο.
 if($turning){
  $turnFraction=[math]::Max(0.0,[math]::Min(1.0,1.0-($p.TurnUntil-$now)/0.24))
  $p.Flip.ScaleX=if($turnFraction -lt 0.50){[double]$p.TurnFrom}else{[double]$p.FacingDir}
  $bodyScaleX*=0.88+0.12*[math]::Abs(2.0*$turnFraction-1.0)
  $headRot*=0.40
 }else{$p.Flip.ScaleX=[double]$p.Dir}
 # Η κύλιση γίνεται γύρω από τον κορμό, όχι από τα πόδια.
 if($p.Mode -eq 'tumble'){
  if($p.Art.RenderTransformOrigin.Y -ne 0.54){$p.Art.RenderTransformOrigin=[System.Windows.Point]::new(0.5,0.54)}
 }else{
  if($p.Art.RenderTransformOrigin.Y -ne 0.60){$p.Art.RenderTransformOrigin=[System.Windows.Point]::new(0.5,0.60)}
 }
 $p.ArtRotation.Angle=$bodyRot
 $p.ArtScale.ScaleX=$bodyScaleX
 $p.ArtScale.ScaleY=$bodyScaleY
 $p.ArtShift.Y=$bob
 $h=if($closed){2}else{10}
 $p.Eye1.Height=$h;$p.Eye2.Height=$h
 $lookUp=($p.Mode -in @('xmas-tangled','xmas-look-up'))
 $eyeTop=if($lookUp){72.0}else{78.0}
 [System.Windows.Controls.Canvas]::SetTop($p.Eye1,$eyeTop+(10-$h)*0.5)
 [System.Windows.Controls.Canvas]::SetTop($p.Eye2,$eyeTop+(10-$h)*0.5)
 $p.Glint1.Visibility=if($closed){'Collapsed'}else{'Visible'}
 $p.Glint2.Visibility=if($closed){'Collapsed'}else{'Visible'}
 $p.ProfileGlint.Visibility=if($closed){'Collapsed'}else{'Visible'}
 [System.Windows.Controls.Canvas]::SetLeft($p.Eye1,49+$p.Gaze)
 [System.Windows.Controls.Canvas]::SetLeft($p.Eye2,83+$p.Gaze)
 [System.Windows.Controls.Canvas]::SetLeft($p.Glint1,51+$p.Gaze)
 [System.Windows.Controls.Canvas]::SetLeft($p.Glint2,85+$p.Gaze)
 $p.Sweat.Visibility=if($p.Mode -eq 'surprise'){'Visible'}else{'Collapsed'}
 $p.Sparkle.Visibility=if($p.Mode -in @('dance','pairdance')){'Visible'}else{'Collapsed'}
 if($p.Mode -in @('dance','pairdance')) {
  [System.Windows.Controls.Canvas]::SetTop($p.Sparkle,32+[math]::Sin($t*7)*9)
 }
 $open=$p.Mode -in @('yawn','laugh','xmas-laugh','xmas-tangled','xmas-look-up','surprise','pairsing') -or (($p.Mode -eq 'eat' -or $p.Mode -eq 'duoeat' -or $p.Mode -eq 'gift-receive') -and [math]::Sin($t*9) -gt 0)
 $p.OpenMouth.Visibility=if($open){'Visible'}else{'Collapsed'}
 $p.SadMouth.Visibility=if($p.Mode -eq 'cry'){'Visible'}else{'Collapsed'}
 $p.Smile.Visibility=if($open -or $p.Mode -eq 'cry'){'Collapsed'}else{'Visible'}
 $p.Heart.Visibility=if($p.Mode -in @('heart','hug')){'Visible'}else{'Collapsed'}
 $p.KissHeart.Visibility=if($p.Mode -eq 'kiss-active' -and $t -gt 0.45 -and $t -lt 2.7){'Visible'}else{'Collapsed'}
 if($p.Mode -eq 'kiss-active'){
  [System.Windows.Controls.Canvas]::SetTop($p.KissHeart,75-8*[math]::Sin($t*4))
 }
 if($p.Mode -in @('heart','hug')){
  [System.Windows.Controls.Canvas]::SetTop($p.Heart,9-[math]::Min(16,$t*8))
 }
 $p.SleepText.Visibility=if($p.Mode -in @('sleep','pairsleep')){'Visible'}else{'Collapsed'}
 $p.MusicNote.Visibility=if($p.Mode -eq 'pairsing'){'Visible'}else{'Collapsed'}
 if($p.Mode -eq 'pairsing'){[System.Windows.Controls.Canvas]::SetTop($p.MusicNote,19-9*[math]::Sin($t*3))}
 # Props are anchored to the computed FK wrists. The paw overlaps the object.
 $flowerGiven=$p.Mode -eq 'flower-give'
 $flowerTaken=$p.Mode -eq 'flower-receive'
 $holdingFlower=(($flowerGiven -and $t -lt 3.5) -or ($flowerTaken -and $t -ge 1.0 -and $t -lt 5.1))
 $p.Flower.Visibility=if($holdingFlower){'Visible'}else{'Collapsed'}
 if($holdingFlower){
  # Stem end directly under the left paw; top of flower extends upward.
  [System.Windows.Controls.Canvas]::SetLeft($p.Flower,$p.WristLX-20)
  [System.Windows.Controls.Canvas]::SetTop($p.Flower,$p.WristLY-59)
 }
 $giving=$p.Mode -eq 'gift-give'
 $receiving=$p.Mode -eq 'gift-receive'
 $holdingCandy=(($giving -and $t -lt 2.5) -or ($receiving -and $t -ge 0.7 -and $t -lt 3.8))
 $p.Candy.Visibility=if($holdingCandy){'Visible'}else{'Collapsed'}
 if($holdingCandy){
  [System.Windows.Controls.Canvas]::SetLeft($p.Candy,$p.WristLX-17)
  [System.Windows.Controls.Canvas]::SetTop($p.Candy,$p.WristLY-17)
 }
 $food=$p.Mode -in @('eat','duoeat','food-offer')
 $p.Cookie.Visibility=if($food){'Visible'}else{'Collapsed'}
 $p.Crumb1.Visibility=if($food){'Visible'}else{'Collapsed'}
 $p.Crumb2.Visibility=if($food){'Visible'}else{'Collapsed'}
 if($food){
  # Biscuit remains attached to the left wrist throughout the bite animation.
  $cx=$p.WristLX-12
  $cy=$p.WristLY-19
  [System.Windows.Controls.Canvas]::SetLeft($p.Cookie,$cx)
  [System.Windows.Controls.Canvas]::SetTop($p.Cookie,$cy)
  [System.Windows.Controls.Canvas]::SetLeft($p.Crumb1,$cx+7)
  [System.Windows.Controls.Canvas]::SetTop($p.Crumb1,$cy+5)
  [System.Windows.Controls.Canvas]::SetLeft($p.Crumb2,$cx+14)
  [System.Windows.Controls.Canvas]::SetTop($p.Crumb2,$cy+14)
 }
 # A short paw overlays the edge of each object, making the grasp readable.
 $grip=($holdingFlower -or $holdingCandy -or $food)
 [System.Windows.Controls.Panel]::SetZIndex($p.ArmLeftHand, $(if($grip){6}else{1}))
 $cry=$p.Mode -eq 'cry'
 $p.Tear1.Visibility=if($cry){'Visible'}else{'Collapsed'}
 $p.Tear2.Visibility=if($cry){'Visible'}else{'Collapsed'}
 if($cry){
  [System.Windows.Controls.Canvas]::SetTop($p.Tear1,82+(($t*64)%43))
  [System.Windows.Controls.Canvas]::SetTop($p.Tear2,82+((($t+0.34)*64)%43))
 }
 # Visible activity props: only the relevant owner displays each object.
 $digging=$p.Mode -eq 'story-sit'
 $p.GroundPlay.Visibility=if($digging){'Visible'}else{'Collapsed'}
 if($digging){$p.GroundStick.Y2=2+4*[math]::Sin($t*7)}
 $p.MiniLaptop.Visibility=if($p.Name -eq 'Dudu' -and $p.Mode -eq 'story-pc'){'Visible'}else{'Collapsed'}
 $p.CameraProp.Visibility=if($p.Name -eq 'Bubu' -and $p.Mode -eq 'story-photo'){'Visible'}else{'Collapsed'}
 $p.SuitcaseProp.Visibility=if($p.Mode -eq 'story-travel'){'Visible'}else{'Collapsed'}
 if($p.Mode -eq 'story-travel'){
  # Οι βαλίτσες μένουν έξω από τα σώματα: αριστερά του αριστερού και δεξιά του δεξιού.
  $suitcaseX=if($p.X -le $p.Partner.X){1.0}else{101.0}
  [System.Windows.Controls.Canvas]::SetLeft($p.SuitcaseProp,$suitcaseX)
  # Αντιστάθμιση της κίνησης bob του Art: η βαλίτσα δεν αναπηδά στον αέρα.
  [System.Windows.Controls.Canvas]::SetTop($p.SuitcaseProp,(99.0-$bob))
 }
 $p.Blanket.Visibility=if($p.Mode -eq 'pairsleep' -and $t -gt 0.7){'Visible'}else{'Collapsed'}
 if($p.Mode -eq 'pairsleep'){
  $blanketTop=106+0.8*[math]::Sin($t*2.2)
  $blanketLeft=if($p.Name -eq 'Bubu'){18}else{10}
  [System.Windows.Controls.Canvas]::SetLeft($p.Blanket,$blanketLeft)
  [System.Windows.Controls.Canvas]::SetTop($p.Blanket,$blanketTop)
 }
 $p.Shadow.Visibility='Visible'
 if($p.Mode -eq 'tumble') {
  $heightAbove=$p.TumbleY-$p.Y
  $p.Shadow.Opacity=[math]::Max(0.14,0.5-$heightAbove/220)
  $p.Shadow.Width=66+[math]::Min(26,$heightAbove*0.36)
 } else {
  $p.Shadow.Opacity=if($standing){0.74}else{[math]::Max(0.16,0.56-[math]::Abs($p.VY)*0.00035)}
  $p.Shadow.Width=if($standing){66}else{[math]::Min(90.0,66.0+[math]::Abs($p.VY)*0.028)}
 }
 $p.W.Left=$p.X;$p.W.Top=$p.Y
}
# Αποφυγή επικάλυψης συννεφιών: μόνο όταν οι δύο χαρακτήρες μιλούν κοντά.
function Get-RectOverlapArea([double]$ax,[double]$ay,[double]$aw,[double]$ah,
                             [double]$bx,[double]$by,[double]$bw,[double]$bh) {
 $width=[math]::Max(0.0,[math]::Min($ax+$aw,$bx+$bw)-[math]::Max($ax,$bx))
 $height=[math]::Max(0.0,[math]::Min($ay+$ah,$by+$bh)-[math]::Max($ay,$by))
 return $width*$height
}
function Get-BubbleOptions($p,[double]$w,[double]$h) {
 # Return named coordinates, not nested arrays. PowerShell's pipeline can flatten arrays.
 $top=20.0-$h
 $outward=if($p.Name -eq 'Bubu'){-1.0}else{1.0}
 if($null -ne $p.Partner){$outward=if($p.X -lt $p.Partner.X){-1.0}else{1.0}}
 $outer=if($outward -lt 0){-$w+10.0}else{134.0}
 if($p.BubbleInitialized){[pscustomobject]@{X=[double]$p.BubbleX;Y=[double]$p.BubbleY}}
 [pscustomobject]@{X=14.0;Y=$top}
 [pscustomobject]@{X=$outer;Y=$top}
 [pscustomobject]@{X=$outer;Y=($top-11.0)}
 [pscustomobject]@{X=14.0;Y=($top-14.0)}
 [pscustomobject]@{X=(0.5*(14.0+$outer));Y=($top-6.0)}
 [pscustomobject]@{X=$outer;Y=38.0}
}
function Bubble-CandidateCost($p,$other,[double]$ox,[double]$oy,[double]$w,[double]$h,[double]$partnerX,[double]$partnerY,[double]$partnerW,[double]$partnerH,[bool]$hasPartner,[double]$horizon) {
 $x=$p.X+$ox;$y=$p.Y+$oy
 $px=$x+$p.BubbleOwnerVX*$horizon
 $py=$y+$p.BubbleOwnerVY*$horizon
 $score=[math]::Abs($ox-14.0)*0.065+[math]::Abs($oy-(24.0-$h))*0.09
 if($p.BubbleInitialized){
  $score+=0.36*([math]::Abs($ox-$p.BubbleX)+[math]::Abs($oy-$p.BubbleY))
 }
 foreach($future in @(0,1)){
  $xx=if($future -eq 0){$x}else{$px}
  $yy=if($future -eq 0){$y}else{$py}
  $score+=500.0*[math]::Max(0.0,$script:area.Left+4.0-$xx)
  $score+=500.0*[math]::Max(0.0,$xx+$w-($script:area.Right-4.0))
  $score+=500.0*[math]::Max(0.0,$script:area.Top+4.0-$yy)
  $score+=500.0*[math]::Max(0.0,$yy+$h-($script:area.Bottom-4.0))
  foreach($person in @($p,$other)){
   $hx=$person.X+14.0;$hy=$person.Y+22.0
   $area=Get-RectOverlapArea $xx $yy $w $h $hx $hy 116.0 109.0
   if($area -gt 0.0){$score+=200000.0+120.0*$area}
  }
  if($hasPartner){
   $area=Get-RectOverlapArea $xx $yy $w $h $partnerX $partnerY $partnerW $partnerH
   if($area -gt 0){$score+=200000.0+120.0*$area}
  }
 }
 return $score
}
function Update-SpeechBubbleLayout($bubu,$dudu,[double]$dt,[double]$now) {
 # Joint, deterministic placement: choose before opening each popup.
 # Speech stays legible; only overlapping balloons slide slowly to a safer offset.
 $pets=@($bubu,$dudu)
 foreach($p in $pets){
  if($null -eq $p){continue}
  $p.BubbleOwnerVX=0.72*$p.BubbleOwnerVX+0.28*(($p.X-$p.BubblePreviousX)/[math]::Max(0.01,$dt))
  $p.BubbleOwnerVY=0.72*$p.BubbleOwnerVY+0.28*(($p.Y-$p.BubblePreviousY)/[math]::Max(0.01,$dt))
  $p.BubblePreviousX=$p.X;$p.BubblePreviousY=$p.Y
  if($p.Speech.Visibility -ne 'Visible'){
   $p.SpeechPopup.IsOpen=$false
   $p.BubbleInitialized=$false
   $p.BubbleMessage=''
   continue
  }
  if($p.BubbleMessage -ne $p.SpeechText.Text -or $p.BubbleW -le 0.0){
   $p.Speech.Measure([System.Windows.Size]::new(148.0,500.0))
   $p.BubbleW=[math]::Max(70.0,[math]::Min(148.0,$p.Speech.DesiredSize.Width))
   $p.BubbleH=[math]::Max(33.0,$p.Speech.DesiredSize.Height)
  }
 }
 $a=$bubu;$b=$dudu
 $showA=($a.Speech.Visibility -eq 'Visible')
 $showB=($b.Speech.Visibility -eq 'Visible')
 if(!$showA -and !$showB){return}
 # Precompute an outer placement for both bubbles, never position sequentially.
 $optA=if($showA){Get-BubbleOptions $a $a.BubbleW $a.BubbleH}else{@()}
 $optB=if($showB){Get-BubbleOptions $b $b.BubbleW $b.BubbleH}else{@()}
 $newA=($showA -and (!$a.BubbleInitialized -or $a.BubbleMessage -ne $a.SpeechText.Text))
 $newB=($showB -and (!$b.BubbleInitialized -or $b.BubbleMessage -ne $b.SpeechText.Text))
 $overlap=$false
 if($showA -and $showB -and !$newA -and !$newB){
  $overlap=(Get-RectOverlapArea ($a.X+$a.BubbleX) ($a.Y+$a.BubbleY) $a.BubbleW $a.BubbleH ($b.X+$b.BubbleX) ($b.Y+$b.BubbleY) $b.BubbleW $b.BubbleH) -gt 0.0
  $futureOverlap=(Get-RectOverlapArea ($a.X+$a.BubbleX+$a.BubbleOwnerVX*0.35) ($a.Y+$a.BubbleY+$a.BubbleOwnerVY*0.35) $a.BubbleW $a.BubbleH ($b.X+$b.BubbleX+$b.BubbleOwnerVX*0.35) ($b.Y+$b.BubbleY+$b.BubbleOwnerVY*0.35) $b.BubbleW $b.BubbleH) -gt 0.0
  $overlap=($overlap -or $futureOverlap)
 }
 # Retain positions while the balloons are not colliding. When a text changes,
 # choose both positions together so no transition starts from a poor guess.
 if($newA -or $newB -or ($overlap -and $now -ge $script:nextBubblePlan)){
  $script:nextBubblePlan=$now+0.25
  $casesA=[System.Collections.ArrayList]::new()
  $casesB=[System.Collections.ArrayList]::new()
  if($showA){foreach($option in @($optA)){[void]$casesA.Add($option)}}else{[void]$casesA.Add([pscustomobject]@{X=0.0;Y=0.0})}
  if($showB){foreach($option in @($optB)){[void]$casesB.Add($option)}}else{[void]$casesB.Add([pscustomobject]@{X=0.0;Y=0.0})}
  $best=[double]::PositiveInfinity
  foreach($oa in $casesA){
   foreach($ob in $casesB){
    $ax=if($showA){[double]$oa.X}else{0.0};$ay=if($showA){[double]$oa.Y}else{0.0}
    $bx=if($showB){[double]$ob.X}else{0.0};$by=if($showB){[double]$ob.Y}else{0.0}
    $cost=0.0
    if($showA){$cost+=Bubble-CandidateCost $a $b $ax $ay $a.BubbleW $a.BubbleH 0 0 0 0 $false 0.35}
    if($showB){$cost+=Bubble-CandidateCost $b $a $bx $by $b.BubbleW $b.BubbleH 0 0 0 0 $false 0.35}
    if($showA -and $showB){
     $area=Get-RectOverlapArea ($a.X+$ax) ($a.Y+$ay) $a.BubbleW $a.BubbleH ($b.X+$bx) ($b.Y+$by) $b.BubbleW $b.BubbleH
     if($area -gt 0){$cost+=400000.0+160.0*$area}
     $future=Get-RectOverlapArea ($a.X+$ax+$a.BubbleOwnerVX*0.35) ($a.Y+$ay+$a.BubbleOwnerVY*0.35) $a.BubbleW $a.BubbleH ($b.X+$bx+$b.BubbleOwnerVX*0.35) ($b.Y+$by+$b.BubbleOwnerVY*0.35) $b.BubbleW $b.BubbleH
     if($future -gt 0){$cost+=250000.0+120.0*$future}
    }
    if($cost -lt $best){$best=$cost;$bestAX=$ax;$bestAY=$ay;$bestBX=$bx;$bestBY=$by}
   }
  }
  if($showA){$a.BubbleTargetX=$bestAX;$a.BubbleTargetY=$bestAY}
  if($showB){$b.BubbleTargetX=$bestBX;$b.BubbleTargetY=$bestBY}
 }
 foreach($p in $pets){
  if($p.Speech.Visibility -ne 'Visible'){continue}
  if(!$p.BubbleInitialized){
   $p.BubbleX=$p.BubbleTargetX;$p.BubbleY=$p.BubbleTargetY
   $p.BubbleInitialized=$true
  }else{
   # Limit to 34 pixels / second independent of refresh rate, no jumps.
   $dx=$p.BubbleTargetX-$p.BubbleX;$dy=$p.BubbleTargetY-$p.BubbleY
   $dist=[math]::Sqrt($dx*$dx+$dy*$dy)
   if($dist -gt 0.08){
    $frac=[math]::Min(1.0,(52.0*$dt)/$dist)
    $p.BubbleX+=$dx*$frac;$p.BubbleY+=$dy*$frac
   }
  }
  $p.BubbleMessage=$p.SpeechText.Text
  # Απευθείας παρακολούθηση της αρκουδίτσας, σε απόλυτες συντεταγμένες οθόνης.
  # ΜΟΝΟ η επιπλέον διόρθωση BubbleX/BubbleY κινείται αργά.
  $p.SpeechPopup.HorizontalOffset=$p.X+$p.BubbleX
  $p.SpeechPopup.VerticalOffset=$p.Y+$p.BubbleY
  if(!$p.SpeechPopup.IsOpen){$p.SpeechPopup.IsOpen=$true}
 }
}

$script:app=[System.Windows.Application]::new()
$script:app.ShutdownMode=[System.Windows.ShutdownMode]::OnExplicitShutdown
Make-ChristmasTree
Make-Pet 'Bubu' ($script:area.Left+120) ($script:area.Bottom-270) 1
Make-Pet 'Dudu' ($script:area.Left+[math]::Min(440,$script:area.Width*0.55)) ($script:area.Bottom-350) -1
$script:pets[0].Partner=$script:pets[1]
$script:pets[1].Partner=$script:pets[0]
Load-LearningMemory
Refresh-Platforms
$timer=[System.Windows.Threading.DispatcherTimer]::new();$timer.Interval=[TimeSpan]::FromMilliseconds(33)
$timer.Add_Tick({
 try{
  $now=$script:watch.Elapsed.TotalSeconds
  $dt=[math]::Min(0.045,[math]::Max(0.001,$now-$script:last))
  $script:last=$now;$script:frame++
  if($script:frame%45 -eq 0){Refresh-Platforms}
  if(!$script:paused){
   $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
   # Κάθε κλάμα της Bubu ενεργοποιεί μία διάσωση, άσχετα με την απόσταση.
   # Η προτεραιότητα είναι πάνω από χορό, γλυκάκια, ύπνο και τυχαία reactions.
   if(!$script:startupGreetingPending -and $null -ne $bubu -and $null -ne $dudu -and $bubu.Mode -eq 'cry' -and !$bubu.Drag -and !$dudu.Drag){
    if($script:pairScene -eq '' -and $now-$script:lastRescueStarted -gt 6.0){
     Start-ComfortScene $now
    }
   }
   # Automatic shared eating: the moment Dudu takes out a snack,
   # Bubu smells it and runs over. Cry/rescue keeps higher priority.
   if(!$script:startupGreetingPending -and $script:pairScene -eq '' -and $dudu.Mode -eq 'eat' -and $bubu.Mode -ne 'cry' -and !$bubu.Drag -and !$dudu.Drag -and $now-$script:lastFoodSmell -gt 70.0 -and $now -ge $script:nextSocialAllowed){
    Start-FoodSmellScene $now
   }
   # Το παιχνίδι με το σφυρί επιλέγεται πλέον αποκλειστικά από το AI.
   Update-Personality $now
   if($script:pairScene -eq 'story-travel-active' -and $null -ne $bubu -and $null -ne $dudu){
    $leftmost=[math]::Min($bubu.X,$dudu.X)
    $rightmost=[math]::Max($bubu.X,$dudu.X)
    if($script:travelDirection -gt 0 -and $rightmost+154.0 -ge $script:area.Right-10.0){$script:travelDirection=-1}
    elseif($script:travelDirection -lt 0 -and $leftmost -le $script:area.Left+10.0){$script:travelDirection=1}
   }
   foreach($p in $script:pets){Move-Pet $p $dt $now}
   # Ο πρώτος χαιρετισμός ξεκινά μόλις και οι δύο αρκούδες πατήσουν έδαφος.
   if($script:startupGreetingPending -and $null -ne $bubu -and $null -ne $dudu -and $bubu.Grounded -and $dudu.Grounded -and !$bubu.Drag -and !$dudu.Drag){
    $script:startupGreetingPending=$false
    Face-Each-Other $bubu $dudu
    $script:pairScene='startup-wave'
    $script:pairStepUntil=$now+8.0
    Set-Mode $bubu 'wave' $now 9.0 'Γεια σου, Dudu!'
    Set-Mode $dudu 'wave' $now 9.0 'Γεια σου, Bubu!'
   }
   Gate-SceneAdvance $now
   # Reaction arbiter runs AFTER Move-Pet: newly uttered 'Νυστάζω' is seen
   # in the same frame, not lost until the next random idle selection.
   if($script:pairScene -eq '' -and !$bubu.Drag -and !$dudu.Drag -and $bubu.Mode -ne 'cry' -and $dudu.Mode -ne 'rescue'){
    if($script:sleepRequestName -ne '' -and $now -le $script:sleepRequestUntil -and $now-$script:lastSleepScene -ge $script:sleepCooldown -and $now -ge $script:nextSocialAllowed){
     Start-PairActivity 'sleep' $now
    } elseif($script:sleepRequestName -ne '' -and $now -gt $script:sleepRequestUntil){
     $script:sleepRequestName='';$script:sleepRequestUntil=0.0
    } elseif($bubu.Energy -lt 17.0 -or $dudu.Energy -lt 17.0){
     if($now-$script:lastSleepScene -ge $script:sleepCooldown -and $now -ge $script:nextSocialAllowed){Start-PairActivity 'sleep' $now}
    }
   }
   if(!$script:startupGreetingPending -and $script:frame%45 -eq 0 -and $script:pairScene -eq '' -and $now -ge $script:nextSocialAllowed -and $now-$script:lastPairScene -gt 42.0){Choose-PersonalityStory $now}

   $bubu=Get-Pet 'Bubu';$dudu=Get-Pet 'Dudu'
   if($null -ne $bubu -and $null -ne $dudu){
    if($script:pairScene -ne '' -and ($bubu.Drag -or $dudu.Drag)){
     Cancel-PairScene $now
    }
    $dx=[math]::Abs($bubu.X-$dudu.X)
    $dy=[math]::Abs($bubu.Y-$dudu.Y)
    $close=($dx -lt 102 -and $dy -lt 56)
    if($script:pairScene -eq 'startup-wave'){
     if(Test-ReactionBarrier $now){
      Set-Mode $bubu 'walk' $now 2.0
      Set-Mode $dudu 'walk' $now 2.0
      $script:pairScene='';$script:lastPairScene=$now
      if($script:christmasDemo -and !$script:christmasDemoStarted){
       $script:christmasDemoStarted=$true
       Start-ChristmasScene $now
      }
     }
    } elseif($script:pairScene -eq 'xmas-decorate'){
     if([math]::Abs($bubu.X-$script:xmasBubuTargetX) -lt 7.0 -and $dy -lt 40.0 -and (Test-SceneDialogueComplete $now)){
      Begin-ChristmasStar $now
     } elseif($now -ge $script:pairStepUntil){
      # Η Bubu συνεχίζει να πλησιάζει, ο Dudu μένει στραμμένος στο δέντρο.
      $script:pairStepUntil=$now+3.0
      $bubu.Until=[math]::Max($bubu.Until,$now+3.2)
      $dudu.Until=[math]::Max($dudu.Until,$now+3.2)
     }
    } elseif($script:pairScene -eq 'xmas-star'){
     if(Test-ReactionBarrier $now){Begin-ChristmasPlug $now}
    } elseif($script:pairScene -eq 'xmas-plug'){
     # Η ηλεκτρική σύνδεση ολοκληρώνεται οπτικά στο 1,7 s.
     if($now-$bubu.ModeStart -ge 1.7){$script:xmasLightsOn=$true}
     if(Test-ReactionBarrier $now){Begin-ChristmasLaugh $now}
    } elseif($script:pairScene -eq 'xmas-laugh'){
     if(Test-ReactionBarrier $now){Finish-ChristmasScene $now}
    } elseif($script:pairScene -like 'story-*'){
     Advance-Story $now $bubu $dudu $dx $dy
    } elseif($script:pairScene -like 'epilogue-*'){
     if(Test-ReactionBarrier $now){
      $script:pairScene=''
      $script:lastPairScene=$now
      $script:separateSince=0.0
     }
    } elseif($script:pairScene -match '^close-(hug|dance)-approach$'){
     $kind=$Matches[1]
     if($dx -le 104 -and $dy -le 17 -and (Test-SceneDialogueComplete $now)){Begin-CloseInteraction $kind $now}
     elseif($now -ge $script:pairStepUntil){
      # Δεν ενεργοποιούμε αγκαλιά/χορό όσο βρίσκονται μακριά.
      Extend-SceneApproach $now $bubu $dudu
     }
    } elseif($script:pairScene -match '^close-(hug|dance)-active$'){
     if(Test-ReactionBarrier $now){End-CloseInteraction $now}
    } elseif($script:pairScene -eq 'kiss-approach'){

     if($dx -le 91 -and $dy -lt 52 -and (Test-SceneDialogueComplete $now)){Continue-KissScene $now}
     elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $bubu $dudu}
    } elseif($script:pairScene -eq 'kiss-active'){
     if(Test-ReactionBarrier $now){Finish-KissScene $now}
    } elseif($script:pairScene -eq 'hammer-chase'){
     if(Test-ReactionBarrier $now){
      End-HammerScene $now
     }
    } elseif($script:pairScene -eq 'food-smell'){
     if($dx -lt 90 -and $dy -lt 56 -and (Test-SceneDialogueComplete $now)){
      Face-Each-Other $bubu $dudu
      Set-Mode $bubu 'duoeat' $now 5.5 'Ευχαριστώ, Dudu! Νόστιμο!'
      Set-Mode $dudu 'duoeat' $now 5.5 'Για σένα, Bubu!'
      $script:pairScene='food-sharing'
      $script:pairStepUntil=$now+5.5
     } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $bubu $dudu}
    } elseif($script:pairScene -in @('meet-eat','meet-love')){
     if(Test-ReactionBarrier $now){
      $script:pairScene=''
      $script:lastPairScene=$now
     }
    } elseif($script:pairScene -eq 'food-sharing'){
     if(Test-ReactionBarrier $now){
      $script:pairScene=''
      $script:lastPairScene=$now
     }
    } elseif($script:pairScene -match '^pair-(flower|sleep|sing)-approach$'){
     $kind=$Matches[1]
     if($dx -lt 96 -and $dy -lt 52 -and (Test-SceneDialogueComplete $now)){Continue-PairActivity $kind $now}
     elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $bubu $dudu}
    } elseif($script:pairScene -match '^pair-(flower|sleep|sing)-active$'){
     if(Test-ReactionBarrier $now){Finish-PairActivity $now}
    } elseif($script:pairScene -eq 'gift-approach'){
     if($dx -lt 94 -and $dy -lt 56 -and (Test-SceneDialogueComplete $now)){
      Face-Each-Other $bubu $dudu
      Set-Mode $dudu 'gift-give' $now 4.0 'Για σένα, Bubu!'
      Set-Mode $bubu 'gift-receive' $now 4.0 'Ευχαριστώ, Dudu!'
      $script:pairScene='gift-share'
      $script:pairStepUntil=$now+4.0
     } elseif($now -ge $script:pairStepUntil){Extend-SceneApproach $now $bubu $dudu}
    } elseif($script:pairScene -eq 'gift-share') {
     if(Test-ReactionBarrier $now){
      Set-Mode $bubu 'heart' $now 2.8 'Σ'' αγαπώ, Dudu!'
      Set-Mode $dudu 'heart' $now 2.8 'Κι εγώ, Bubu!'
      Begin-SceneEpilogue 'gift' $now 2.8
     }
    } elseif($script:pairScene -eq 'comfort'){
     if($close -and (Test-SceneDialogueComplete $now)){
      Face-Each-Other $bubu $dudu
      Set-Mode $bubu 'hug' $now 3.0 'Dudu!'
      Set-Mode $dudu 'hug' $now 3.0 'Bubu!' 
      $script:pairScene='comfort-dance'
      $script:pairStepUntil=$now+2.5
     } elseif($now -ge $script:pairStepUntil){
      Extend-SceneApproach $now $bubu $dudu
     }
    } elseif($script:pairScene -eq 'comfort-dance') {
     if(Test-ReactionBarrier $now){
      Face-Each-Other $bubu $dudu
      Set-Mode $bubu 'pairdance' $now 4.4 'Μαζί με τον Dudu!'
      Set-Mode $dudu 'pairdance' $now 4.4 'Μαζί με την Bubu!' 
      Begin-SceneEpilogue 'comfort' $now 4.4
     }
    } else {
     if($dx -gt 240){
      if($script:separateSince -le 0){$script:separateSince=$now}
      elseif($now-$script:separateSince -gt 26){$script:separateSince=$now} # Personal distance is NOT distress.
     } else { $script:separateSince=0.0 }
     # Οι κοινωνικές σκηνές επιλέγονται μόνο από το ενιαίο Personality AI.
    }
   }
   # Complete a shared scene once; reserve independent playtime before a new one.
   if($script:prevPairScene -ne '' -and $script:pairScene -eq ''){
    $script:soloUntil=$now+20.0+$script:random.NextDouble()*16.0
    $script:nextSocialAllowed=$now+48.0+$script:random.NextDouble()*20.0
    $script:nextStory=[math]::Max($script:nextStory,$script:nextSocialAllowed)
    $script:sleepRequestName='';$script:sleepRequestUntil=0.0
   }
   $script:prevPairScene=$script:pairScene
   Update-ChristmasVisual $now
   Update-SpeechSystem $now
   # Ενημέρωση Q μόνον όταν έχει τελειώσει η σκηνή και όλες οι ατάκες της.
   if($null -ne $script:learnPending){Complete-LearningEpisode $now}
   if($null -ne $bubu -and $null -ne $dudu){
    try{Update-SpeechBubbleLayout $bubu $dudu $dt $now}
    catch{
     foreach($pet in @($bubu,$dudu)){
      if($pet.Speech.Visibility -eq 'Visible'){
       $pet.SpeechPopup.HorizontalOffset=$pet.X+14.0
       $pet.SpeechPopup.VerticalOffset=$pet.Y-72.0
       $pet.SpeechPopup.IsOpen=$true
      } else { $pet.SpeechPopup.IsOpen=$false }
     }
     throw
    }
   }
  }
 }catch{
  if(($script:watch.Elapsed.TotalSeconds-$script:lastLoggedError) -gt 2.0){
   $script:lastLoggedError=$script:watch.Elapsed.TotalSeconds
   try{Add-Content -Path (Join-Path $PSScriptRoot 'error.log') -Value "$(Get-Date -Format s) $($_.Exception.Message)" -Encoding UTF8}catch{}
  }
 }
})
$timer.Start()
try{[void]$script:app.Run()}finally{$timer.Stop();Hide-ChristmasScene;Save-LearningMemory}
