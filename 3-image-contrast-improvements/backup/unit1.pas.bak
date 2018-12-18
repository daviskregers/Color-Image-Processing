unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ExtDlgs, LCLType, IntfGraphics, GraphType, ComCtrls, Menus, Math;

type

  TPixel = record       //pikselis, glabās informāciju par 3 krāsas kanāliem
    R,G,B,I: Byte;
  end;

  THistogram = array [0..256] of integer;
  TRGBIHistogram = record
  R,G,B,I: THistogram;
  end;

   TXYZPixel = record
    X,Y,Z: real; //no 0 līdz 1
  end;

  TLabPixel = record
    L,a,b: Shortint; // no 0 līdz 100
  end;


  TimgArray = array of array of TPixel;

  TRGBTripleArray = array[0..32767] of TRGBTriple; //bibliotēka LCLType
  PRGBTripleArray = ^TRGBTripleArray;  //izmanto lai skenēt rindas

  TXYZArray = array of array of TXYZPixel;
  TLabArray = array of array of TLabPixel;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    RadioGroup1: TRadioGroup;
    TrackBar1: TTrackBar;
    TrackBar2: TTrackBar;
    TrackBar3: TTrackBar;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);

    procedure ReadFromImage();
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure TrackBar3Change(Sender: TObject);
    procedure WriteToImage(img: TImgArray; tImg: TImage; mode: String);
    procedure ReadHistograms(hst: TRGBIHistogram; img: TImgArray; tImg: TImage);
    procedure DrawHistograms(hst: TRGBIHistogram; tImg: TImage);


  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  img1, img2: TImgArray;
  hst1, hst2, hst_clear: TRGBIHistogram;

  xyzArr: TXYZArray;
  LabArr: TLabArray;

implementation

{$R *.lfm}
function RGBtoXYZ(p: TPixel): TXYZPixel;
var
    var_R, var_G, var_B: real;
begin

     var_R := p.R / 255;
     var_G := p.G / 255;
     var_B := p.B / 255;

     if( var_R > 0.04045) then
       var_R := power(((var_R + 0.055)/1.055), 2.4)
     else
       var_R := (var_R / 12.92);

     if( var_G > 0.04045) then
       var_G := power(((var_G + 0.055)/1.055), 2.4)
     else
       var_G := (var_G / 12.92);

     if( var_B > 0.04045) then
       var_B := power(((var_R + 0.055)/1.055), 2.4)
     else
       var_B := (var_B / 12.92);

     RGBtoXYZ.X := var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805;
     RGBtoXYZ.Y := var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722;
     RGBtoXYZ.Z := var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505;

end;
function XYZtoRGB(p: TXYZPixel): TPixel;
var
      var_X, var_Y, var_Z: real;
      var_R, var_G, var_B: real;
begin
     var_X := p.X / 100;
     var_Y := p.Y / 100;
     var_Z := p.Z / 100;

     var_R := var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986;
     var_G := var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415;
     var_B := var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570;

     if ( var_R > 0.0031308 ) then
       var_R := 1.055 * ( power( var_R, ( 1 / 2.4 ) ) ) - 0.055
     else
       var_R := 12.92 * var_R;

     if ( var_G > 0.0031308 ) then
       var_G := 1.055 * ( power( var_G, ( 1 / 2.4 ) ) ) - 0.055
     else
       var_G := 12.92 * var_G;

     if ( var_B > 0.0031308 ) then
       var_B := 1.055 * ( power( var_B, ( 1 / 2.4 ) ) ) - 0.055
     else
       var_B := 12.92 * var_B;

   XYZtoRGB.R := round(var_R * 255);
   XYZtoRGB.G := round(var_G * 255);
   XYZtoRGB.B := round(var_B * 255);

end;
function LabtoXYZ(p: TLabPixel): TXYZPixel;
var var_X, var_Y, var_Z: real;
begin
     var_Y := (p.L + 16) / 116;
     var_X := p.A / 500 + var_Y;
     var_Z := var_Y - p.B / 200;

     if ( power(var_Y, 3) > 0.008856 ) then
        var_Y := power(var_Y, 3)
     else
        var_Y := ( var_Y - 16 / 116 ) / 7.787;

     if ( power(var_X, 3) > 0.008856 ) then
         var_X := power(var_X, 3)
     else
         var_X := ( var_X - 16 / 116 ) / 7.787;

     if ( power(var_Z, 3) > 0.008856 ) then
        var_Z := power(var_Z, 3)
     else
         var_Z := ( var_Z - 16 / 116 ) / 7.787;

     LabtoXYZ.X := 95.047 * var_X;
     LabtoXYZ.Y := 100.00 * var_Y;
     LabtoXYZ.Z := 108 * var_Z;
end;
function XYZtoLab(p: TXYZPixel): TLabPixel;
var var_X, var_Y, var_Z: real;
begin
     var_X := p.X / 0.95;
     var_Y := p.Y / 1;
     var_Z := p.Z / 1.08883;

     if ( var_X > 0.008856 ) then
        var_X := power(var_X , ( 1/3 ))
     else
       var_X := ( 7.787 * var_X ) + ( 16 / 116 );

     if ( var_Y > 0.008856 ) then
       var_Y := power(var_Y , ( 1/3 ))
     else
       var_Y := ( 7.787 * var_Y ) + ( 16 / 116 );

     if ( var_Z > 0.008856 ) then
       var_Z := power(var_Z , ( 1/3 ))
     else
       var_Z := ( 7.787 * var_Z ) + ( 16 / 116 );

  XYZtoLab.L := round(( 116 * var_Y ) - 16);
  XYZtoLab.A := round(500 * ( var_X - var_Y ));
  XYZtoLab.B := round(200 * ( var_Y - var_Z ));
end;


procedure TForm1.ReadHistograms(hst: TRGBIHistogram; img: TImgArray; tImg: TImage);
var px,py: integer;
begin
     hst := hst_clear; // clear

     for py:= 0 to High(img[0]) do  //skenē imgLaz attelu
        begin
          setlength(img2, Length(img), Length(img[0]));
          for px:=0 to High(img) do  //skenē rindu
            begin

              inc(hst.R[img[px,py].R]);
              hst.R[256] := Max( hst.R[256], hst.R[img[px,py].R]);

              inc(hst.G[img[px,py].G]);
              hst.G[256] := Max( hst.G[256], hst.G[img[px,py].G]);

              inc(hst.B[img[px,py].B]);
              hst.B[256] := Max( hst.B[256], hst.B[img[px,py].B]);

              inc(hst.I[img[px,py].I]);
              hst.I[256] := Max( hst.I[256], hst.I[img[px,py].I]);

            end;
        end;

     DrawHistograms(hst, tImg);

end;

procedure TForm1.DrawHistograms(hst: TRGBIHistogram; tImg: TImage);
var i: integer;
begin
tImg.Canvas.Clear;
  tImg.Canvas.Pen.Color := clRed;
    tImg.Canvas.MoveTo(0, 100 - round(hst.R[0] / hst.R[256] * 100));
    for i:= 1 to 255 do
      begin
        tImg.Canvas.LineTo(i, 100-round(hst.R[i]/hst.R[256]*100))
      end;

    tImg.Canvas.Pen.Color := clGreen;
  tImg.Canvas.MoveTo(0, 100 - round(hst.G[0] / hst.G[256] * 100));
  for i:= 1 to 255 do
    begin
      tImg.Canvas.LineTo(i, 100-round(hst.G[i]/hst.G[256]*100))
    end;

  tImg.Canvas.Pen.Color := clBlue;
  tImg.Canvas.MoveTo(0, 100 - round(hst.B[0] / hst.B[256] * 100));
  for i:= 1 to 255 do
    begin
      tImg.Canvas.LineTo(i, 100-round(hst.B[i]/hst.B[256]*100))
    end;

  tImg.Canvas.Pen.Color := clBlack;
  tImg.Canvas.MoveTo(0, 100 - round(hst.I[0] / hst.I[256] * 100));
  for i:= 1 to 255 do
    begin
      tImg.Canvas.LineTo(i, 100-round(hst.I[i]/hst.I[256]*100))
    end;
end;

procedure TForm1.ReadFromImage();
var i,px,py: integer;
    row: pRGBTripleArray;
    lazImage : TLazIntfImage;
    rawImage: TRawImage;
begin
   If OpenPictureDialog1.Execute then
  begin
    rawImage.Init;                                       //inicializācija
    rawImage.Description.Init_BPP24_B8G8R8_BIO_TTB(0,0); //24 bitu formāts
    rawImage.CreateData(false);                          //veido datus (tukšus)

    lazImage:=TLazIntfImage.Create(0,0);    //veido imgLaz lai kaut ko tur ierakstīt
    lazImage.SetRawImage(rawImage);        //formāts tiek nolasīts no imgData
    lazImage.LoadFromFile(OpenPictureDialog1.FileName);        //ielādē failu
    SetLength(img1,lazImage.Width,lazImage.Height);            //uzdod masīva izmērus
    SetLength(img2,0,0);

    for py:= 0 to High(img1[0]) do  //skenē imgLaz attelu
      begin
        Row:=lazImage.GetDataLineStart(py); //nolasa rindu
        for px:=0 to High(img1) do  //skenē rindu
          begin
            img1[px,py].R:=Row^[px].rgbtRed;
            img1[px,py].G:=Row^[px].rgbtGreen;
            img1[px,py].B:=Row^[px].rgbtBlue;
            img1[px,py].I:=round(0.2126 * img1[px,py].R + 0.7152 * img1[px,py].G + 0.0722 * img1[px,py].B);
          end;
      end;

    Image1.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz
    Image2.Picture.Bitmap:=nil;
    lazImage.Free;  //atbrīvo atmiņu
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
var px,py: integer;
    y: float;
begin
   if(Length(img1) > 0) then
   begin

     y := TrackBar1.Position * 0.05;

     Label5.Caption := FloatToStr( y )  ;

     for py:= 0 to High(img1[0]) do  //skenē imgLaz attelu
        begin

          setlength(img2, Length(img1), Length(img1[0]));
          setlength(xyzArr, Length(img1), Length(img1[0]));
          setlength(LabArr, Length(img1), Length(img1[0]));

          for px:=0 to High(img1) do  //skenē rindu
            begin

              xyzArr[px,py] := RGBtoXYZ(img2[px,py]);
              LabArr[px,py] := XYZtoLab(xyzArr[px,py]);

              img2[px,py].R := round( power( (img1[px,py].R / 255), y ) * 255 );
              img2[px,py].G := round( power( (img1[px,py].G / 255), y ) * 255 );
              img2[px,py].B := round( power( (img1[px,py].B / 255), y ) * 255 );
              img2[px,py].I := round( power( (img1[px,py].I / 255), y ) * 255 );



            end;
        end;

     Case RadioGroup1.ItemIndex of
       0: begin
         if Length(img1)>0 then
         WriteToImage(img1, Image1, 'RGB');
         if Length(img2)>0 then
         WriteToImage(img2, Image2, 'RGB');
       end;
       1: begin
         if Length(img1)>0 then
         WriteToImage(img1, Image1, 'I');
         if Length(img2)>0 then
         WriteToImage(img2, Image2, 'I');
       end;
       2: begin
               if Length(img1)>0 then
               WriteToImage(img1, Image1, 'LAB');
               if Length(img2)>0 then
               WriteToImage(img2, Image2, 'LAB');
             end;
    end;

     ReadHistograms(hst1, img1, Image3);
     ReadHistograms(hst2, img2, Image4);

   end;
end;

procedure TForm1.TrackBar2Change(Sender: TObject);
var px,py: integer;
    y: float;
begin

   if(Length(img1) > 0) then
   begin

     y := TrackBar2.Position * 0.05;

     Label6.Caption := FloatToStr( y )  ;

     for py:= 0 to High(img1[0]) do  //skenē imgLaz attelu
        begin
          setlength(img2, Length(img1), Length(img1[0]));
          setlength(xyzArr, Length(img1), Length(img1[0]));
          setlength(LabArr, Length(img1), Length(img1[0]));

          for px:=0 to High(img1) do  //skenē rindu
            begin

              img2[px,py].R := min(255, round(log2((img1[px,py].R / 255) + 1) / log2(2) * y * 255));
              img2[px,py].G := min(255, round(log2((img1[px,py].G / 255) + 1) / log2(2) * y * 255));
              img2[px,py].B := min(255, round(log2((img1[px,py].B / 255) + 1) / log2(2) * y * 255));
              img2[px,py].I := min(255, round(log2((img1[px,py].I / 255) + 1) / log2(2) * y * 255));

            end;
        end;

     Case RadioGroup1.ItemIndex of
  0: begin
       if Length(img1)>0 then
       WriteToImage(img1, Image1, 'RGB');
       if Length(img2)>0 then
       WriteToImage(img2, Image2, 'RGB');
     end;
  1: begin
       if Length(img1)>0 then
       WriteToImage(img1, Image1, 'I');
       if Length(img2)>0 then
       WriteToImage(img2, Image2, 'I');
     end;
  2: begin
               if Length(img1)>0 then
               WriteToImage(img1, Image1, 'LAB');
               if Length(img2)>0 then
               WriteToImage(img2, Image2, 'LAB');
             end;
  end;

     ReadHistograms(hst1, img1, Image3);
   ReadHistograms(hst2, img2, Image4);

   end;



end;

procedure TForm1.TrackBar3Change(Sender: TObject);
var px,py: integer;
    y: float;
begin

   if(Length(img1) > 0) then
   begin

     y := TrackBar3.Position * 0.05;

     Label9.Caption := FloatToStr( y )  ;

     for py:= 0 to High(img1[0]) do  //skenē imgLaz attelu
        begin
          setlength(img2, Length(img1), Length(img1[0]));
          setlength(xyzArr, Length(img1), Length(img1[0]));
          setlength(LabArr, Length(img1), Length(img1[0]));
          for px:=0 to High(img1) do  //skenē rindu
            begin

              img2[px,py].R := min(255, round((power(2, (img1[px,py].R / 255) ) - 1) * y * 255));
              img2[px,py].G := min(255, round((power(2, (img1[px,py].G / 255) ) - 1) * y * 255));
              img2[px,py].B := min(255, round((power(2, (img1[px,py].B / 255) ) - 1) * y * 255));
              img2[px,py].I := min(255, round((power(2, (img1[px,py].I / 255) ) - 1) * y * 255));

            end;
        end;

       Case RadioGroup1.ItemIndex of
          0: begin
               if Length(img1)>0 then
               WriteToImage(img1, Image1, 'RGB');
               if Length(img2)>0 then
               WriteToImage(img2, Image2, 'RGB');
             end;
          1: begin
               if Length(img1)>0 then
               WriteToImage(img1, Image1, 'I');
               if Length(img2)>0 then
               WriteToImage(img2, Image2, 'I');
             end;
          2: begin
               if Length(img1)>0 then
               WriteToImage(img1, Image1, 'LAB');
               if Length(img2)>0 then
               WriteToImage(img2, Image2, 'LAB');
             end;

       end;

       ReadHistograms(hst1, img1, Image3);
       ReadHistograms(hst2, img2, Image4);

   end;

end;

procedure TForm1.WriteToImage(img: TImgArray; tImg: TImage; mode: String);
var   px,py: integer;
      row: pRGBTripleArray;
      lazImage : TLazIntfImage;
      rawImage: TRawImage;
begin
  rawImage.Init;                                       //inicializācija
  rawImage.Description.Init_BPP24_B8G8R8_BIO_TTB(0,0); //24 bitu formāts
  rawImage.CreateData(false);                          //veido datus (tukšus)

  lazImage:=TLazIntfImage.Create(0,0);    //veido imgLaz lai kaut ko tur ierakstīt
  lazImage.SetRawImage(rawImage);        //formāts tiek nolasīts no imgData
  lazImage.SetSize(Length(img),Length(img[0]));  //attēla izmēri

  for py:= 0 to High(img[0]) do //skenē imgLaz attelu
    begin
      Row:=lazImage.GetDataLineStart(py); //nolasa rindu
      for px:=0 to High(img) do  //skenē rindu
        if Mode='RGB' then
            begin
               Row^[px].rgbtRed:=img[px,py].R;
               Row^[px].rgbtGreen:=img[px,py].G;
               Row^[px].rgbtBlue:=img[px,py].B;
             end
        else if Mode='I' then
            begin
               Row^[px].rgbtRed:=img[px,py].I;
               Row^[px].rgbtGreen:=img[px,py].I;
               Row^[px].rgbtBlue:=img[px,py].I;
             end
        else if Mode='LAB' then
        begin
               Row^[px].rgbtRed :=round(XYZtoRGB(LabtoXYZ(XYZtoLab(RGBtoXYZ(img[px,py])))).R);
               Row^[px].rgbtGreen :=round(XYZtoRGB(LabtoXYZ(XYZtoLab(RGBtoXYZ(img[px,py])))).G);
               Row^[px].rgbtBlue :=round(XYZtoRGB(LabtoXYZ(XYZtoLab(RGBtoXYZ(img[px,py])))).B);
          end;
    end;
  tImg.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz
  lazImage.Free;  //atbrīvo atmiņu
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  ReadFromImage();
end;

procedure TForm1.Label3Click(Sender: TObject);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  TrackBar1Change(Sender);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  TrackBar2Change(Sender);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 TrackBar3Change(Sender);
end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  Case RadioGroup1.ItemIndex of
    0: begin
         if Length(img1)>0 then
         WriteToImage(img1, Image1, 'RGB');
         if Length(img2)>0 then
         WriteToImage(img2, Image2, 'RGB');
       end;
    1: begin
         if Length(img1)>0 then
         WriteToImage(img1, Image1, 'I');
         if Length(img2)>0 then
         WriteToImage(img2, Image2, 'I');
       end;
    2: begin
         if Length(img1)>0 then
         WriteToImage(img1, Image1, 'LAB');
         if Length(img2)>0 then
         WriteToImage(img2, Image2, 'LAB');
       end;
  end;
end;

end.

