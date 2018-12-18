unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ExtDlgs, LCLType, IntfGraphics, GraphType, ComCtrls, Menus, Grids,
  ValEdit, Math, dbf;

type

  TPixel = record       //pikselis, glabās informāciju par 3 krāsas kanāliem
    R,G,B,I: Byte;
  end;


  TimgArray = array of array of TPixel;

  TRGBTripleArray = array[0..32767] of TRGBTriple; //bibliotēka LCLType
  PRGBTripleArray = ^TRGBTripleArray;  //izmanto lai skenēt rindas

  THistogram = array [0..256] of integer;

  TRGBIHistogram = record
    R,G,B,I: THistogram;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    RadioGroup1: TRadioGroup;
    StringGrid1: TStringGrid;

    procedure Button1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);

    procedure CalculateHistogram(var hst: THistogram; mode: String);

    procedure ReadFromImage();
    procedure WriteToImage(img: TImgArray; tImg: TImage; mode: String);

    procedure ReadHistograms(var hst: TRGBIHistogram; img: TImgArray);
    procedure DrawHistograms(hst: TRGBIHistogram; tImg: TImage);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  img1, img2: TImgArray;
  hst1, hst2: TRGBIHistogram;
  Table: record
    hx: array[0..255] of real; // orģinālās histogrammas normalizētas vērtības
    yHx: array [0..255] of real; //oriģinālās histogrammas sadalījuma funkcija y = Hx
    yHz: array [0..255] of real; //ideālās histogrammas sadalījuma funkcija y = Hz
    zj: array [0..255] of integer; //jauna atbilstoša intensitāte
  end;

implementation

{$R *.lfm}

procedure TForm1.CalculateHistogram(var hst: THistogram; mode: String);
var NM, i, j, starpkey: integer;
    yHx, MinStarpiba, Starpiba: real;
begin
     // 1. Attīra StringGrid1
     StringGrid1.Clean(0,0,255,255,[gznormal]);
     // 2.  Jāuzdod img2 izmērus, kas būs vienādi ar img1 izmēriem
     NM := Length(img1) * Length(img1[0]);
     StringGrid1.RowCount := Length(hst) + 1;

     // 3-5. Tabulā hx jāieraksta vērtības

     yHx := 0;

         for i := 0 to High(hst) do
         begin
           Table.hx[i] := hst[i] / NM;
           yHx := yHx + Table.hx[i];
           Table.yHx[i] := yHx;
           Table.yHz[i] := (i+1) / 256;

             StringGrid1.Cells[1,i+1] :=  IntToStr(i);
             StringGrid1.Cells[2,i+1] :=  FloatToStr(Table.hx[i]);
             StringGrid1.Cells[3,i+1] :=  FloatToStr(Table.yHx[i]);
             StringGrid1.Cells[4,i+1] :=  FloatToStr(Table.yHz[i]);


         end;

         for i := 0 to High(hst) do
         begin

             MinStarpiba := 999999999999999;
             starpkey := 0;

             for j := 0 to High(hst) do
             begin
                  Starpiba := Table.yHx[i] - Table.yHz[j];

                  if ( (Starpiba < MinStarpiba) and (Starpiba > 0) ) then
                  begin
                      MinStarpiba := Starpiba;
                      starpkey := j;
                  end;

                  if( j = High(hst) ) then
                  begin
                       Table.zj[i] := starpkey;

                       StringGrid1.Cells[5,i+1] :=  IntToStr(Table.zj[i]);


                  end;
             end;
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
    ReadHistograms(hst1,img1);
    DrawHistograms(hst1,Image3);
    Image1.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz
    Image2.Picture.Bitmap:=nil;
    lazImage.Free;  //atbrīvo atmiņu
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
    end;
  tImg.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz
  lazImage.Free;  //atbrīvo atmiņu
end;

procedure TForm1.ReadHistograms(var hst: TRGBIHistogram; img: TImgArray);
var i, px, py: integer;
begin
  for i:=0 to 256 do
    begin
      hst.R[i]:=0;
      hst.G[i]:=0;
      hst.B[i]:=0;
      hst.I[i]:=0;
    end;

  for px:= 0 to High(img) do
    for py:= 0 to High(img[0]) do
      begin
        inc(hst.R[img[px,py].R]);
        hst.R[256]:=Max(hst.R[256],hst.R[img[px,py].R]);

        inc(hst.G[img[px,py].G]);
        hst.G[256]:=Max(hst.G[256],hst.G[img[px,py].G]);

        inc(hst.B[img[px,py].B]);
        hst.B[256]:=Max(hst.B[256],hst.B[img[px,py].B]);

        inc(hst.I[img[px,py].I]);
        hst.I[256]:=Max(hst.I[256],hst.I[img[px,py].I]);
      end;
end;

procedure TForm1.DrawHistograms(hst: TRGBIHistogram; tImg: TImage);
var i,j: integer;
begin
  tImg.Canvas.Brush.Color:=clGray;
  tImg.Canvas.FillRect(0,0,tImg.Width,tImg.Height);

  tImg.Canvas.Pen.Color:=clRed;
  tImg.Canvas.MoveTo(0,100-Round(hst.R[0]/hst.R[256]*100));
  for i:=1 to 255 do
    begin
      tImg.Canvas.LineTo(i,100-Round(hst.R[i]/hst.R[256]*100))
    end;

  tImg.Canvas.Pen.Color:=clGreen;
  tImg.Canvas.MoveTo(0,100-Round(hst.G[0]/hst.G[256]*100));
  for i:=1 to 255 do
    begin
      tImg.Canvas.LineTo(i,100-Round(hst.G[i]/hst.G[256]*100))
    end;

  tImg.Canvas.Pen.Color:=clBlue;
  tImg.Canvas.MoveTo(0,100-Round(hst.B[0]/hst.B[256]*100));
  for i:=1 to 255 do
    begin
      tImg.Canvas.LineTo(i,100-Round(hst.B[i]/hst.B[256]*100))
    end;

  tImg.Canvas.Pen.Color:=clBlack;
  tImg.Canvas.MoveTo(0,100-Round(hst.I[0]/hst.I[256]*100));
  for i:=1 to 255 do
    begin
      tImg.Canvas.LineTo(i,100-Round(hst.I[i]/hst.I[256]*100))
    end;
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  ReadFromImage();
end;

procedure TForm1.Button1Click(Sender: TObject);
var px, py: integer;
begin
     if(Length(img1) > 0) then
         begin

           setlength(img2, Length(img1), Length(img1[0]));

           CalculateHistogram(hst1.R, 'R');

           for px:= 0 to High(img1) do
            for py:= 0 to High(img1[0]) do
              begin
                img2[px,py].R := Table.zj[img1[px,py].R];
              end;

           CalculateHistogram(hst1.G, 'G');

           for px:= 0 to High(img1) do
            for py:= 0 to High(img1[0]) do
              begin
                img2[px,py].G := Table.zj[img1[px,py].G];
              end;

           CalculateHistogram(hst1.B, 'B');

           for px:= 0 to High(img1) do
            for py:= 0 to High(img1[0]) do
              begin
                img2[px,py].B := Table.zj[img1[px,py].B];
              end;

           CalculateHistogram(hst1.I, 'I');

           for px:= 0 to High(img1) do
            for py:= 0 to High(img1[0]) do
              begin
                img2[px,py].I := Table.zj[img1[px,py].I];
              end;
         end;

         Case RadioGroup1.ItemIndex of
              0: begin
                 if Length(img2)>0 then WriteToImage(img2, Image2, 'RGB');
              end;
              1: begin
                 if Length(img2)>0 then WriteToImage(img2, Image2, 'I');
              end;
         end;

         ReadHistograms(hst2, img2);
         DrawHistograms(hst2, Image4);
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
  end;
end;


end.

