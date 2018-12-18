unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ExtDlgs, LCLType, IntfGraphics, GraphType, Math;

type

  TRGBPixel = record       //pikselis, glabās informāciju par 3 krāsas kanāliem
    R,G,B,I: Byte;
  end;

  TXYZPixel = record
    X,Y,Z: real; //no 0 līdz 1
  end;

  TLabPixel = record
    L,a,b: Shortint; // no 0 līdz 100
  end;

  TRGBArray = array of array of TRGBPixel;
  TXYZArray = array of array of TXYZPixel;
  TLabArray = array of array of TLabPixel;

  TRGBTripleArray = array[0..32767] of TRGBTriple; //bibliotēka LCLType
  PRGBTripleArray = ^TRGBTripleArray;  //izmanto lai skenēt rindas

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    OpenPictureDialog1: TOpenPictureDialog;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    SavePictureDialog1: TSavePictureDialog;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure Label1Click(Sender: TObject);

    procedure RadioGroup1Click(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure ReadFromImage(var img: TRGBArray);
    procedure WriteToImage(img: TRGBArray; mode: string);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  imgOrg, imgArr: TRGBArray; {masīvi, kas glabās informāciju, oriģinālais un pārveidotais}
  xyzArr: TXYZArray;
  LabArr: TLabArray;
  RGBArr: TRGBArray;

implementation

{$R *.lfm}

function RGBtoXYZ(p: TRGBPixel): TXYZPixel;
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
function XYZtoRGB(p: TXYZPixel): TRGBPixel;
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

   XYZtoRGB.R := byte(round(var_R * 255));
   XYZtoRGB.G := byte(round(var_G * 255));
   XYZtoRGB.B := byte(round(var_B * 255));

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


procedure TForm1.ReadFromImage(var img: TRGBArray);
var px,py: integer;  //cikla skaitītāji, izmantoju px un py, jo tie ir uzskatāmāki, nekā i un j
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
    SetLength(img,lazImage.Width,lazImage.Height);            //uzdod masīva izmērus

    for py:= 0 to High(img[0]) do  //skenē imgLaz attelu
      begin
        if py = 0 then
          begin
            setlength(xyzArr, Length(img), Length(img[0]));
            setlength(LabArr, Length(img), Length(img[0]));
            setlength(RGBArr, Length(img), Length(img[0]));
          end;
        Row:=lazImage.GetDataLineStart(py); //nolasa rindu
        for px:=0 to High(img) do  //skenē rindu
          begin
            img[px,py].R:=Row^[px].rgbtRed;
            img[px,py].G:=Row^[px].rgbtGreen;
            img[px,py].B:=Row^[px].rgbtBlue;
            img[px,py].I:=round(0.2126 * img[px,py].R + 0.7152 * img[px,py].G + 0.0722 * img[px,py].B);
            xyzArr[px,py] := RGBtoXYZ(img[px,py]);
            LabArr[px,py] := XYZtoLab(xyzArr[px,py]);
            RGBArr[px,py] := XYZtoRGB(LabtoXYZ(LabArr[px,py]));
          end;
      end;
    imgArr := img;
    Image1.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image1 ielādē datus no imgLaz
    lazImage.Free;  //atbrīvo atmiņu
  end;
end;
procedure TForm1.WriteToImage(img: TRGBArray; mode: string);
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
        Case Mode of
          'Composite': begin
                 Row^[px].rgbtRed:=img[px,py].R;
                 Row^[px].rgbtGreen:=img[px,py].G;
                 Row^[px].rgbtBlue:=img[px,py].B;
               end;
          'Red': begin
                 Row^[px].rgbtRed:=img[px,py].R;
                 Row^[px].rgbtGreen:=0;
                 Row^[px].rgbtBlue:=0;
               end;
          'Green': begin
                 Row^[px].rgbtRed:=0;
                 Row^[px].rgbtGreen:=img[px,py].G;
                 Row^[px].rgbtBlue:=0;
               end;
          'Blue': begin
                 Row^[px].rgbtRed:=0;
                 Row^[px].rgbtGreen:=0;
                 Row^[px].rgbtBlue:=img[px,py].B;
               end;
          'Intensity': begin
                 Row^[px].rgbtRed:=img[px,py].I;
                 Row^[px].rgbtGreen:=img[px,py].I;
                 Row^[px].rgbtBlue:=img[px,py].I;
               end;
          'Lightness': begin

                 Row^[px].rgbtRed :=round(XYZtoLab(RGBtoXYZ(img[px,py])).L)*255 div 100;
                 Row^[px].rgbtGreen :=round(XYZtoLab(RGBtoXYZ(img[px,py])).L)*255 div 100;
                 Row^[px].rgbtBlue :=round(XYZtoLab(RGBtoXYZ(img[px,py])).L)*255 div 100;
          end;

          'a': begin

                 Row^[px].rgbtRed := 128 +( 128 * round(XYZtoLab(RGBtoXYZ(img[px,py])).A) div 100 );
                 Row^[px].rgbtGreen := 128 -( 128 * round(XYZtoLab(RGBtoXYZ(img[px,py])).A) div 100 );
                 Row^[px].rgbtBlue := 128 +( 128 * round(XYZtoLab(RGBtoXYZ(img[px,py])).A) div 100 );
          end;

          'b': begin

                 Row^[px].rgbtRed:= 128 +( 128 * round(XYZtoLab(RGBtoXYZ(img[px,py])).B) div 100 );
                 Row^[px].rgbtGreen:= 128 +( 128 * round(XYZtoLab(RGBtoXYZ(img[px,py])).B) div 100 );
                 Row^[px].rgbtBlue:= 128 -( 128 * round(XYZtoLab(RGBtoXYZ(img[px,py])).B) div 100 );
          end;
        end;
    end;
  Image1.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image1 ielādē datus no imgLaz
  lazImage.Free;  //atbrīvo atmiņu
end;


procedure TForm1.Button1Click(Sender: TObject);
begin
  ReadFromImage(imgOrg);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  If SavePictureDialog1.Execute then
    Image1.Picture.Bitmap.SaveToFile(SavePictureDialog1.FileName);
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var xn, yn: integer;
begin
  if(length(imgArr) > 0) then
    begin
     xn := round(X * Max(length(imgArr), length(imgArr[0])) / Image1.Width);
     yn := round(Y * Max(length(imgArr), length(imgArr[0])) / Image1.Width);

     Label1.Caption := concat('R: ',IntToStr(imgArr[xn,yn].R),'; G: ',IntToStr(imgArr[xn,yn].G),'; B: ', IntToStr(imgArr[xn,yn].B));
     Label2.Caption := concat('X: ',FloatToStr(xyzArr[xn,yn].X),'; Y: ',FloatToStr(xyzArr[xn,yn].Y),'; Z: ', FloatToStr(xyzArr[xn,yn].Z));
     Label3.Caption := concat('L: ',IntToStr(LabArr[xn,yn].L),'; A: ',IntToStr(LabArr[xn,yn].A),'; B: ', IntToStr(LabArr[xn,yn].B));
     Label4.Caption := concat('R: ',IntToStr(RGBArr[xn,yn].R),'; G: ',IntToStr(RGBArr[xn,yn].G),'; B: ', IntToStr(RGBArr[xn,yn].B));

    end
  else Label1.Caption := 'imgArr empty';
end;

procedure TForm1.Label1Click(Sender: TObject);
begin

end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
var px,py: integer;
begin
  Case Radiogroup1.ItemIndex of
    0: begin
         RadioGroup2.Items.Clear;
         RadioGroup2.Items.Add('Composite');
         RadioGroup2.Items.Add('Red');
         RadioGroup2.Items.Add('Green');
         RadioGroup2.Items.Add('Blue');
         RadioGroup2.ItemIndex:=0;
       end;
    1: begin
         RadioGroup2.Items.Clear;
         RadioGroup2.Items.Add('Lightness');
         RadioGroup2.Items.Add('a');
         RadioGroup2.Items.Add('b');
         RadioGroup2.ItemIndex:=0;
       end;
  end;

      if (RadioGroup1.ItemIndex=0) and (Length(imgOrg)>0) then
        WriteToImage(imgOrg,RadioGroup2.Items[RadioGroup2.ItemIndex]);
end;

procedure TForm1.RadioGroup2Click(Sender: TObject);
begin
      if (RadioGroup1.ItemIndex=0) and (Length(imgOrg)>0) then
        WriteToImage(imgOrg,RadioGroup2.Items[RadioGroup2.ItemIndex]);
      if (RadioGroup1.ItemIndex=1) and (Length(imgOrg)>0) then
        WriteToImage(imgOrg,RadioGroup2.Items[RadioGroup2.ItemIndex]);
end;



end.

