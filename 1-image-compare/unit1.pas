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

  TZone = record
        x1, y1, x2, y2, w,h: integer;
        p1, p2: real;
  end;

  TError = record
        er: real;
        erkv: real;
  end;

  TimgArray = array of array of TPixel;
  TErrArray = array of array of TError;

  TRGBTripleArray = array[0..32767] of TRGBTriple; //bibliotēka LCLType
  PRGBTripleArray = ^TRGBTripleArray;  //izmanto lai skenēt rindas

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure Image2MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image3MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );

    procedure ReadFromImage(var img: TImgArray; tImg: TImage; source: integer);
    procedure WriteToImage(img: TImgArray; tImg: TImage; source: integer);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  img1, img2, img3: TImgArray;
  z: TZone;
  mouseClicked: boolean;
  mouseX, mouseY: real;
  errArray: TErrArray;
implementation

{$R *.lfm}


procedure TForm1.ReadFromImage(var img: TImgArray; tImg: TImage; source: integer );
var px,py: integer;
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

      tImg.Canvas.Brush.Style := bsClear;
  tImg.Canvas.Pen.Color := clRed;
  tImg.Canvas.Pen.Width := 4;

    for py:= 0 to High(img[0]) do  //skenē imgLaz attelu
      begin
        Row:=lazImage.GetDataLineStart(py); //nolasa rindu
        for px:=0 to High(img) do  //skenē rindu
          begin
            img[px,py].R:=Row^[px].rgbtRed;
            img[px,py].G:=Row^[px].rgbtGreen;
            img[px,py].B:=Row^[px].rgbtBlue;
            img[px,py].I:=round(0.2126 * img[px,py].R + 0.7152 * img[px,py].G + 0.0722 * img[px,py].B);
          end;
      end;

    // Pārklāšanās zonas izmēri

     z.x1 := 0;
     z.x2 := 0;
     z.y1 := 0;
     z.y2 := 0;

    if ((length(img1) > 0) and (length(img2) > 0)) then
    begin
         z.w := min( Length(img1), Length(img2) );
         z.h := min( Length(img1[0]), Length(img2[0]) );


         if max(Length(img1), Length(img1[0])) <= Image1.Width then
            z.p1 := 1
         else
            z.p1 :=  max(Length(img1), Length(img1[0])) / Image1.Width;

         if max(Length(img2), Length(img2[0])) <= Image2.Width  then
            z.p2 := 1
         else
            z.p2 :=  max(Length(img2), Length(img2[0])) / Image2.Width;

    end
    else
        begin
             if (source = 1) then
                begin
                z.w := Length(img1);
                z.h := Length(img1[0]);
                end
             else
                 begin
                    z.w := Length(img2);
                    z.h := Length(img2[0]);
                 end;
          end;

    tImg.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz

    if (source = 1) then
        tImg.Picture.Bitmap.Canvas.Rectangle(z.x1, z.y1, z.x1 + z.w, z.y1 + z.h)
    else
        tImg.Picture.Bitmap.Canvas.Rectangle(z.x2, z.y2, z.x2 + z.w, z.y2 + z.h);

      lazImage.Free;  //atbrīvo atmiņu
  end;
end;

procedure TForm1.WriteToImage(img: TImgArray; tImg: TImage; source: integer);
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

  tImg.Canvas.Brush.Style := bsClear;
  tImg.Canvas.Pen.Color := clRed;
  tImg.Canvas.Pen.Width := 4;

  for py:= 0 to High(img[0]) do //skenē imgLaz attelu
    begin
      Row:=lazImage.GetDataLineStart(py); //nolasa rindu
      for px:=0 to High(img) do  //skenē rindu
            begin
               Row^[px].rgbtRed:=img[px,py].R;
               Row^[px].rgbtGreen:=img[px,py].G;
               Row^[px].rgbtBlue:=img[px,py].B;
             end;
    end;
  tImg.Picture.Bitmap.LoadFromIntfImage(lazImage);  //Image ielādē datus no imgLaz

  if (source = 1) then
        tImg.Picture.Bitmap.Canvas.Rectangle(z.x1, z.y1, z.x1 + z.w, z.y1 + z.h)
  else
      begin
           if (source = 2) then
              tImg.Picture.Bitmap.Canvas.Rectangle(z.x2, z.y2, z.x2 + z.w, z.y2 + z.h);
      end;


  lazImage.Free;  //atbrīvo atmiņu
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ReadFromImage(img1, Image1, 1);
    if(length(img2) > 0) then
     WriteToImage(img2, Image2, 2);

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ReadFromImage(img2, Image2, 2);
  if(length(img1) > 0) then
     WriteToImage(img1, Image1, 1);

end;

procedure TForm1.Button3Click(Sender: TObject);
var   px, py: integer;
      i1, i2, i3: TPixel;
      errN: TError;
      Emax, Ekv: real;
begin
  Emax := 0;
  Ekv := 0;

  setlength(errArray,z.w,z.h);
  setlength(img3,z.w,z.h);

  for px:= 0 to z.w -1 do
  begin

       for py:= 0 to z.h -1 do
       begin

              i1 := img1[z.x1+px][z.y1+py];
              i2 := img2[z.x2+px][z.y2+py];

              errN.er := (
                          abs(i1.R - i2.R) +
                          abs(i1.G - i2.G) +
                          abs(i1.B - i2.B) +
                          abs(i1.I - i2.I)
                          ) / 4;
              errN.erkv :=  errN.er *  errN.er;
              errArray[px][py] := errN;

              if errN.er > Emax then // Emax
                 Emax := errN.er;

              Ekv := Ekv +  errN.erkv;

         i3.R := round((i1.R + i2.R) / 2);
         i3.G := round((i1.G + i2.G) / 2);
         i3.B := round((i1.B + i2.B) / 2);
         i3.I := round((i1.I + i2.I) / 2);

         img3[px][py] := i3;

       end;
  end;

  //Ekv
  Ekv := 1 / (z.w * z.h) * Ekv;

  Label7.Caption := FloatToStr(Ekv);
  Label8.Caption := FloatToStr(Emax);


  WriteToImage(img3, Image3, 3);

end;

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
      mouseClicked := true;

      if( z.p1 <> 0) then
         begin
               mouseX := round(X - z.x1 / z.p1);
               mouseY := round(Y - z.y1 / z.p1);
         end;

end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
  var debug: TCaption;
begin

  if(mouseClicked = true) then
     begin
        z.x1 := round((X - mouseX) * z.p1);
        z.y1 := round((Y - mouseY) * z.p1);

        if z.x1 < 0 then z.x1 := 0;
        if z.x1 + z.w > length(img1) then z.x1 := length(img1) - z.w;
        if z.y1 < 0 then z.y1 := 0;
        if z.y1 + z.h > length(img1[0]) then z.y1 := length(img1[0]) - z.h;



        Label9.Caption :=
                        concat(
                                 'X=' , IntToStr(z.x1),
                               '; Y=',IntToStr(z.y1),
                               '; W=',IntToStr(length(img1[0])),
                               '; H=',IntToStr(length(img1)),
                               '; ZW=',IntToStr(z.w),
                               '; ZH=',IntToStr(z.h),
                               '; ZP=',FloatToStr(z.p1)
                               );

        WriteToImage(img1, Image1, 1);
     end;

end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     mouseClicked := false;
end;

procedure TForm1.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     mouseClicked := true;
     if( z.p2 <> 0) then
         begin
               mouseX := X - z.x2 / z.p2;
               mouseY := Y - z.y2 / z.p2;
         end;
end;

procedure TForm1.Image2MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin

     if(mouseClicked = true) then
        begin
           z.x2 := round((X - mouseX) * z.p2);
           z.y2 := round((Y - mouseY) * z.p2);

           if z.x2 < 0 then z.x2 := 0;
           if z.x2 + z.w > length(img2) then z.x2 := length(img2) - z.w;
           if z.y2 < 0 then z.y2 := 0;
           if z.y2 + z.h > length(img2[0]) then z.y2 := length(img2[0]) - z.h;



           Label9.Caption :=
                           concat(
                                    'X=' , IntToStr(z.x2),
                                  '; Y=',IntToStr(z.y2),
                                  '; W=',IntToStr(length(img2[0])),
                                  '; H=',IntToStr(length(img2)),
                                  '; ZW=',IntToStr(z.w),
                                  '; ZH=',IntToStr(z.h),
                                  '; ZP=',FloatToStr(z.p2)
                                  );

           WriteToImage(img2, Image2, 2);
        end;

end;

procedure TForm1.Image2MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     mouseClicked := false;
end;

procedure TForm1.Image3MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
  var xn, yn: integer;
begin
  if(length(errArray) > 0) then
     begin
     xn := round(X * Max(length(errArray), length(errArray[0])) / Image3.Width);
     yn := round(Y * Max(length(errArray), length(errArray[0])) / Image3.Width);
      Label2.Caption := concat(
          'X, Y = (',
          IntToStr(xn),
          ',',
          IntToStr(yn),
          '); Erkv = ',
          FloatToStr(errArray[xn][yn].erkv),
          '; E = ',
          FloatToStr(errArray[xn][yn].er)
      );
     end;
end;

end.

