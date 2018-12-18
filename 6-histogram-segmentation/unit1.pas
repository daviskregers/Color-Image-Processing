unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ExtDlgs, LCLType, IntfGraphics, GraphType, ComCtrls, Menus, Math;

type

  TPixel = record       //pikselis, glabās informāciju par 3 krāsas kanāliem
    R,G,B,I: Byte;
    S: integer; //segmenta numurs pikselim
  end;


  TimgArray = array of array of TPixel;

  TRGBTripleArray = array[0..32767] of TRGBTriple; //bibliotēka LCLType
  PRGBTripleArray = ^TRGBTripleArray;  //izmanto lai skenēt rindas

  THistogram = array [0..256] of record
    N: integer;  //Pikselu skaits dotajā intensitātē
    S: integer;  //segmenta numurs dotai intensitātei
  end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    TrackBar1: TTrackBar;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);

    procedure ReadFromImage();
    procedure TrackBar1Change(Sender: TObject);
    procedure WriteToImage(img: TImgArray; var image: TImage);

    procedure ReadHistogram();
    procedure ReadHistogram2();
    procedure ReadHistogram3();
    procedure DrawHistogram();
    procedure DrawHistogram2();

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  img1, img2: TImgArray;
  hst1: THistogram;
  hst2: THistogram;
  COL: array of TColor;
  tVertical: array of record
    s: integer;
    g: integer;
  end;
  inside: boolean;
  i,j: integer;
  tmp: integer;

implementation

{$R *.lfm}

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
    ReadHistogram();
    SetLength(COL,255);
    COL[0]:=clBlack;
    for px:=1 to 255 do
      begin
        COL[px] := RGBToColor(Random(255), Random(255), Random(255));
      end;

    DrawHistogram();
    WriteToImage(img1, Image1);
    Image2.Picture.Bitmap:=nil;
    lazImage.Free;  //atbrīvo atmiņu
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  if Length(img1)>0 then
  begin

    DrawHistogram();
    Image3.Canvas.Pen.Color:=clRed;
    Image3.Canvas.MoveTo(0,TrackBar1.Position);
    Image3.Canvas.LineTo(Image3.Width,TrackBar1.Position);

  end;
end;

procedure TForm1.WriteToImage(img: TImgArray; var image: TImage);
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
            begin
               Row^[px].rgbtRed:=img[px,py].R;
               Row^[px].rgbtGreen:=img[px,py].G;
               Row^[px].rgbtBlue:=img[px,py].B;
             end
    end;
  Image.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz
  lazImage.Free;  //atbrīvo atmiņu
end;


procedure TForm1.ReadHistogram();
var i, px, py: integer;
begin
  for i:=0 to 256 do
    begin
      hst1[i].N:=0;
    end;

  for px:= 0 to High(img1) do
    for py:= 0 to High(img1[0]) do
      begin
        inc(hst1[img1[px,py].I].N);
        hst1[256].N:=Max(hst1[256].N,hst1[img1[px,py].I].N);
      end;

end;

procedure TForm1.ReadHistogram2();
var i, px, py: integer;
      inside: bool;
      lastSection: integer;
      value: integer;
      maxVal: integer;
begin
  for i:=0 to 256 do
    begin
      hst1[i].N:=0;
    end;

  for px:= 0 to High(img1) do
    for py:= 0 to High(img1[0]) do
      begin
        inc(hst1[img1[px,py].I].N);
        hst1[256].N:=Max(hst1[256].N,hst1[img1[px,py].I].N);
      end;

  lastSection := 0;
  inside := false;

  maxVal := -99999;

  for px:= 0 to High(hst1) do
    begin
         if( hst1[px].N > maxVal ) then
         begin
           maxVal := hst1[px].N;
         end;
    end;

  hst2 := hst1;
  inside := false;
  inc(lastSection);

  for px:= 0 to High(hst1) do
    begin

           value := 100-Round(hst1[px].N/hst1[256].N*100);
           if((inside = false) and (value <= (TrackBar1.Position))) then
           begin
             inside := true;
             inc(lastSection);
             hst2[px].S := lastSection;

           end
           else if((inside = true) and (value <= (TrackBar1.Position))) then
           begin
             hst2[px].S := lastSection;
           end
           else begin
             inside := false;
           end;

    end;

end;


procedure TForm1.ReadHistogram3();
var i, px, py: integer;
      inside: bool;
      lastSection: integer;
      value: integer;
      maxVal: integer;
begin
  for i:=0 to 256 do
    begin
      hst1[i].N:=0;
    end;

  for px:= 0 to High(img1) do
    for py:= 0 to High(img1[0]) do
      begin
        inc(hst1[img1[px,py].I].N);
        hst1[256].N:=Max(hst1[256].N,hst1[img1[px,py].I].N);
      end;

  lastSection := 0;
  inside := false;

  maxVal := -99999;

  for px:= 0 to High(hst1) do
    begin
         if( hst1[px].N > maxVal ) then
         begin
           maxVal := hst1[px].N;
         end;
    end;

  hst2 := hst1;
  inside := false;
  inc(lastSection);

  for px:= 0 to High(hst1) do
    begin

           value := 100-Round(hst1[px].N/hst1[256].N*100);
           if((inside = false) and (value <= (TrackBar1.Position))) then
           begin
             inside := true;
             inc(lastSection);
             hst2[px].S := lastSection;

           end
           else if((inside = true) and (value <= (TrackBar1.Position))) then
           begin
             hst2[px].S := lastSection;
           end
           else begin
             inside := false;
             hst2[px].S := lastSection;
           end;

    end;

end;

procedure TForm1.DrawHistogram();
var i,j: integer;
begin
  Image3.Canvas.Brush.Color:=clGray;
  Image3.Canvas.FillRect(0,0,Image3.Width,Image3.Height);

  for i:=0 to 255 do
    begin
      Image3.Canvas.Pen.Color:=COL[hst1[i].S];
      Image3.Canvas.MoveTo(i,100);
      Image3.Canvas.LineTo(i,100-Round(hst1[i].N/hst1[256].N*100));
    end;
end;


procedure TForm1.DrawHistogram2();
var i,j: integer;
begin
  Image3.Canvas.Brush.Color:=clGray;
  Image3.Canvas.FillRect(0,0,Image3.Width,Image3.Height);

  for i:=0 to 255 do
    begin
      Image3.Canvas.Pen.Color:=COL[hst2[i].S];
      Image3.Canvas.MoveTo(i,100);
      Image3.Canvas.LineTo(i,100-Round(hst2[i].N/hst2[256].N*100));

      Image3.Canvas.Pen.Color:=clRed;
      Image3.Canvas.MoveTo(0,TrackBar1.Position);
      Image3.Canvas.LineTo(Image3.Width,TrackBar1.Position);

    end;
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  ReadFromImage();
end;

procedure TForm1.Button1Click(Sender: TObject);
var px, py: integer;
begin

  for px:=1 to 255 do
      begin
        COL[px] := RGBToColor(Random(255), Random(255), Random(255));
      end;

  ReadHistogram2();
  DrawHistogram2();

  img2 := img1;

  for px:= 0 to High(img1) do
    for py:= 0 to High(img1[0]) do
      begin

        img2[px,py].R := Round(
                               0.5 * img2[px,py].I +
                               0.5 * Red(ColorToRGB(COL[hst2[img2[px,py].I].S]))
                               );
        img2[px,py].G := Round(
                               0.5 * img2[px,py].I +
                               0.5 * Green(ColorToRGB(COL[hst2[img2[px,py].I].S]))
                               );
        img2[px,py].B := Round(
                               0.5 * img2[px,py].I +
                               0.5 * Blue(ColorToRGB(COL[hst2[img2[px,py].I].S]))
                               );


      end;

  WriteToImage(img2, Image2);

end;

procedure TForm1.Button2Click(Sender: TObject);
var px,py: integer;
begin
  for px:=1 to 255 do
      begin
        COL[px] := RGBToColor(Random(255), Random(255), Random(255));
      end;

  ReadHistogram3();
  DrawHistogram2();

   img2 := img1;

  for px:= 0 to High(img1) do
    for py:= 0 to High(img1[0]) do
      begin

        img2[px,py].R := Round(
                               0.5 * img2[px,py].I +
                               0.5 * Red(ColorToRGB(COL[hst2[img2[px,py].I].S]))
                               );
        img2[px,py].G := Round(
                               0.5 * img2[px,py].I +
                               0.5 * Green(ColorToRGB(COL[hst2[img2[px,py].I].S]))
                               );
        img2[px,py].B := Round(
                               0.5 * img2[px,py].I +
                               0.5 * Blue(ColorToRGB(COL[hst2[img2[px,py].I].S]))
                               );


      end;

  WriteToImage(img2, Image2);
end;


end.

