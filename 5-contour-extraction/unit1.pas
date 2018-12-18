unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ExtDlgs, LCLType, IntfGraphics, GraphType, ComCtrls, Menus, Grids,
  MaskEdit, Math;

type

  TPixel = record       //pikselis, glabās informāciju par 3 krāsas kanāliem
    R,G,B,I: Byte;
    gradStrength: integer;
    gradDirection: integer;
  end;


  TimgArray = array of array of TPixel;

  TRGBTripleArray = array[0..32767] of TRGBTriple; //bibliotēka LCLType
  PRGBTripleArray = ^TRGBTripleArray;  //izmanto lai skenēt rindas

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    StringGrid1: TStringGrid;
    TrackBar1: TTrackBar;
    UpDown1: TUpDown;

    procedure Button1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);

    // CUSTOM PROCEDURES & FUNCTIONS

    procedure CreateFilter();
    procedure GausaFiltrs();
    procedure SobelaOperators();
    procedure NemaksimaloIzt();

    function gradDirection( theta: real ): integer;
    function atan2( y, x: real ): real;

    // CUSTOM PROCEDURES & FUNCTIONS
    procedure ReadFromImage();
    procedure TrackBar1Change(Sender: TObject);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure WriteToImage(img: TImgArray; tImg: TImage; mode: String);


  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  img1, img2, img3: TImgArray;
  Kernel: array of array of real;
  Summa: real;
  nonmax_deleted, kernel_size: integer;

implementation

{$R *.lfm}

procedure TForm1.CreateFilter();
var izm, x, y, start, ending, k: integer;
      sigma, r, s: float;
begin
  sigma := StrToFloat(Edit2.Text);
  izm := StrToInt(Edit1.Text);
  setlength(Kernel, izm, izm);

  k := floor((izm - 1) / 2);

  start := -1 * k;
  ending := k;
  s := 2.0 * sigma;

  StringGrid1.ColCount := izm;
  StringGrid1.RowCount := izm;
  StringGrid1.Clean(0,0,255,255,[gznormal]);
  Summa := 0;

  for x := start to ending do
    for y := start to ending do
      begin
           r := Sqrt(x*x + y*y);
           Kernel[x+ending, y+ending] := (exp(-(r*r)/s))/(Pi * s);
           Summa := Summa + Kernel[x+ending, y+ending];
           StringGrid1.Cells[x+ending,y+ending] :=  FloatToStr(Kernel[x+ending, y+ending]);
      end;

end;

function TForm1.gradDirection( theta: real ): integer;
begin
  if(((theta >= 0) and (theta <= 22.5)) or ((theta >= 157.5) and (theta <= 180))) then
      gradDirection := 1
  else if ((theta >= 22.5) and (theta < 67.5)) then
      gradDirection := 2
  else if ((theta >= 67.5) and (theta < 112.5)) then
      gradDirection := 3
  else if ((theta >= 112.5) and (theta < 157.5)) then
      gradDirection := 4;
end;

function TForm1.atan2( y, x: real ): real;
begin
  if(x = 0) and (y = 0) then
      atan2 := 0
  else if ( (y < 0) and (x = 0) ) then
      atan2 := - Pi / 2
  else if ( (y > 0) and (x = 0) ) then
      atan2 := Pi / 2
  else if ( (y < 0) and (x < 0) ) then
      atan2 := ArcTan( (y/x) - Pi )
  else if ( (y >= 0) and (x < 0) ) then
      atan2 := ArcTan( (y/x) + Pi )
  else if ( x > 0 ) then
      atan2 := ArcTan( (y/x) );
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
    SetLength(img2,lazImage.Width,lazImage.Height);
    SetLength(img3,lazImage.Width,lazImage.Height);

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
begin
   Edit2.Text :=   FloatToStr(TrackBar1.Position * 0.1 + 0.5);
end;

procedure TForm1.UpDown1Click(Sender: TObject; Button: TUDBtnType);
var value: integer;
begin

  case Button of
    btNext: value := StrToInt(Edit1.Text) + 2;
    btPrev: value := StrToInt(Edit1.Text) - 2;
  end;

   if(value > 15) then value := 15;
   if(value < 3) then value := 3;
   Edit1.Text:= IntToStr(value);

   StringGrid1.ColCount := value;
    StringGrid1.RowCount := value;
    StringGrid1.Clean(0,0,255,255,[gznormal]);

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

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  ReadFromImage();
end;

procedure TForm1.GausaFiltrs();
var yo, xo, x, y, m, n, xox, yoy, h,w: integer;
      gr,gg,gb,gi: real;
begin

  w := High(img1);
  h := High(img1[0]);
  setlength(img2, w+1, h+1);

  //img2 := img1;

  n := floor((StrToInt(Edit1.Text) - 1) / 2);

  // Gausa Filtrs

  For xo :=0 to w Do
      For yo :=0 to h Do
  Begin

          gr := 0; gg := 0; gb := 0; gi := 0;

           For y := -n to n Do
           For x := -n to n Do
              Begin

              if(xo+x) < 0 then xox := 0
              else if (xo + x) > w then xox := w
              else xox := xo + x;

              if(yo+y) < 0 then yoy := 0
              else if (yo + y) > h then yoy := h
              else yoy := yo + y;

               gr := gr + Kernel[x+n, y+n] * img1[xox,yoy].R;
               gg := gg + Kernel[x+n, y+n] * img1[xox,yoy].G;
               gb:= gb + Kernel[x+n, y+n] * img1[xox,yoy].B;
               gi := gi + Kernel[x+n, y+n] * img1[xox,yoy].I;

              End;

           if( gr > 255 ) then gr := 255;
           if( gg > 255 ) then gg := 255;
           if( gb > 255 ) then gb := 255;
           if( gi > 255 ) then gi := 255;

           img2[xo, yo].R := round(gr);
           img2[xo, yo].G := round(gg);
           img2[xo, yo].B := round(gb);
           img2[xo, yo].I := round(gi);
  End;

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

procedure TForm1.SobelaOperators();

var yo, xo, h,w, rowOffset, colOffset, rowTotal, colTotal, p, opSize: integer;
      thisAngle, GGx, GGy, Gvid: real;
      fx, fy: array of array of integer;

begin

  w := High(img1);
  h := High(img1[0]);

  OpSize := 3;
  setlength(fx, OpSize, OpSize);
  setlength(fy, OpSize, OpSize);

  Case RadioGroup2.ItemIndex of
          0: begin

                Label8.Caption := Concat('Mode: Sobell');

                fx[0,0] := -1; fx[0,1] := 0; fx[0,2] := 1;
                fx[1,0] := -2; fx[1,1] := 0; fx[1,2] := 2;
                fx[2,0] := -1; fx[2,1] := 0; fx[2,2] := 1;

                fy[0,0] := -1; fy[0,1] := -2; fy[0,2] := -1;
                fy[1,0] := 0; fy[1,1] := 0; fy[1,2] := 0;
                fy[2,0] := +1; fy[2,1] := +2; fy[2,2] := +1;
             end;
          1: begin

                Label8.Caption := Concat('Mode: Roberts');

                fx[0,0] := 0; fx[0,1] := 0; fx[0,2] := 0;
                fx[1,0] := 0; fx[1,1] := 1; fx[1,2] := 0;
                fx[2,0] := 0; fx[2,1] := 0; fx[2,2] := -1;

                fy[0,0] := 0; fy[0,1] := 0; fy[0,2] := 0;
                fy[1,0] := 0; fy[1,1] := 1; fy[1,2] := 0;
                fy[2,0] := -1; fy[2,1] := 0; fy[2,2] := 0;
             end;
          2: begin

                Label8.Caption := Concat('Mode: Prewit');

                fx[0,0] := -1; fx[0,1] := 0; fx[0,2] := 1;
                fx[1,0] := -1; fx[1,1] := 0; fx[1,2] := 1;
                fx[2,0] := -1; fx[2,1] := 0; fx[2,2] := 1;

                fy[0,0] := -1; fy[0,1] := -1; fy[0,2] := -1;
                fy[1,0] := 0; fy[1,1] := 0; fy[1,2] := 0;
                fy[2,0] := +1; fy[2,1] := +1; fy[2,2] := +1;
          end;
          3: begin
                Label8.Caption := Concat('Mode: Scharr');

                fx[0,0] := 3; fx[0,1] := 10; fx[0,2] := +3;
                fx[1,0] := -10; fx[1,1] := 0; fx[1,2] := 10;
                fx[2,0] := -3; fx[2,1] := -10; fx[2,2] := -3;

                fy[0,0] := 3; fy[0,1] := -10; fy[0,2] := -3;
                fy[1,0] := 10; fy[1,1] := 0; fy[1,2] := -10;
                fy[2,0] := +3; fy[2,1] := +10; fy[2,2] := -3;
          end;
  end;

  For xo :=0 to (w-ceil(kernel_size/2)) Do
      For yo :=0 to (h-ceil(kernel_size/2)) Do
  Begin

       GGx := 0; GGy := 0;
       p := kernel_size - 2;

             For rowOffset := 0 to OpSize-1 do
                 For colOffset := 0 to OpSize-1 do
             begin

                rowTotal := xo + rowOffset -ceil(kernel_size/2);
                colTotal := yo + colOffset -ceil(kernel_size/2);

                if (rowTotal >= 0) and (colTotal >= 0) and (rowTotal <= h) and (colTotal <= w) then
                begin
                    GGx := GGx + img2[rowTotal, colTotal].I * fx[rowOffset][colOffset];
                    GGy := GGy + img2[rowTotal, colTotal].I * fy[rowOffset][colOffset];
                end;

             end;

             img2[xo,yo].gradStrength := round( sqrt( ( GGx*GGx ) + ( GGy*GGy ) ) );
             if img2[xo,yo].gradStrength > 255 then img2[xo,yo].gradStrength := 255;

             //img2[xo, yo].gradStrength := round( sqrt(GGx*GGx + GGy*GGy) );

             thisAngle := ((atan2(GGx, GGy) / 3.14159) * 180);

              if ( ( (thisAngle < 22.5) and (thisAngle > -22.5) ) or (thisAngle > 157.5) or (thisAngle < -157.5) ) then
                  img2[xo, yo].gradDirection := 0;
              if ( ( (thisAngle > 22.5) and (thisAngle < 67.5) ) or ( (thisAngle < -112.5) and (thisAngle > -157.5) ) ) then
                  img2[xo, yo].gradDirection := 45;
              if ( ( (thisAngle > 67.5) and (thisAngle < 112.5) ) or ( (thisAngle < -67.5) and (thisAngle > -112.5) ) ) then
                  img2[xo, yo].gradDirection := 90;
              if ( ( (thisAngle > 112.5) and (thisAngle < 157.5) ) or ( (thisAngle < -22.5) and (thisAngle > -67.5) ) ) then
                  img2[xo, yo].gradDirection := 135;

             img2[xo, yo].R := img2[xo, yo].gradStrength;
             img2[xo, yo].G := img2[xo, yo].gradStrength;
             img2[xo, yo].B := img2[xo, yo].gradStrength;

  End;


end;

procedure TForm1.NemaksimaloIzt();
var w, h, xo, yo, minThreshold, maxThreshold, nonEdge, StrongEdge, WeakEdge : integer;
    cont: bool;
    maxStrength, minStrength: real;
    nonmax: array of array of integer;
begin
  setlength(nonmax, Length(img2), Length(img2[0]));

  w := High(img2);
  h := High(img2[0]);

  img3 := img2;

  minThreshold := StrToInt(Edit3.Text);
  maxThreshold := StrToInt(Edit4.Text);

  // NEMAKSIMĀLO VĒRTĪBU IZTĪRĪŠANA
  for yo := 1 to h-1 do
    for xo := 1 to w-1 do
      begin

           if (img3[xo, yo].gradDirection = 0) then
               if (img3[xo,yo].gradStrength < img3[xo,yo + 1].gradStrength)
                  or (img3[xo,yo].gradStrength < img3[xo,yo - 1].gradStrength) then
                      begin
                        img3[xo,yo].gradStrength := 0;
                      end;


           if (img3[xo, yo].gradDirection = 45) then
               if (img3[xo,yo].gradStrength < img3[xo - 1,yo + 1].gradStrength)
                  or (img3[xo,yo].gradStrength < img3[xo + 1,yo - 1].gradStrength) then
                      begin
                        img3[xo,yo].gradStrength := 0;
                      end;


           if (img3[xo, yo].gradDirection = 90) then
               if (img3[xo,yo].gradStrength < img3[xo - 1 ,yo].gradStrength)
                  or (img3[xo,yo].gradStrength < img3[xo + 1,yo].gradStrength) then
                      begin
                        img3[xo,yo].gradStrength := 0;
                      end;


           if (img3[xo, yo].gradDirection = 135) then
               if (img3[xo,yo].gradStrength < img3[xo - 1,yo - 1].gradStrength)
                  or (img3[xo,yo].gradStrength < img3[xo + 1,yo + 1].gradStrength) then
                      begin
                        img3[xo,yo].gradStrength := 0;
                      end;

      end;

      // DIVKĀRŠAIS SLIEKSNIS

      for yo := 1 to h-1 do
          for xo := 1 to w-1 do
      begin

           if(img3[xo,yo].gradStrength >= maxThreshold) then begin img3[xo,yo].gradStrength := 100; end
           else if(img3[xo,yo].gradStrength < maxThreshold) and (img3[xo,yo].gradStrength > minThreshold) then begin img3[xo,yo].gradStrength := 50; end
           else begin img3[xo,yo].gradStrength := 0; img3[xo,yo].gradStrength := 0; end;

      end;



      // HISTERĒZE

      for yo := 1 to h-1 do
                for xo := 1 to w-1 do
            begin

              cont := True;
              while( cont ) do
              begin
                   cont := False;

                             if(img3[xo,yo].gradStrength = 50) then
                                 begin
                                   if  (
                                        (img3[xo-1,yo-1].gradStrength = 100) or
                                        (img3[xo-1,yo].gradStrength = 100) or
                                        (img3[xo-1,yo+1].gradStrength = 100) or

                                        (img3[xo,yo-1].gradStrength = 100) or
                                        (img3[xo,yo+1].gradStrength = 100) or

                                        (img3[xo+1,yo-1].gradStrength = 100) or
                                        (img3[xo+1,yo].gradStrength = 100) or
                                        (img3[xo+1,yo+1].gradStrength = 100)
                                   ) then begin
                                       img3[xo,yo].gradStrength := 100;
                                       cont := True;
                                   end;
                                 end

               end;
      end;

      for yo := 1 to h-1 do
        for xo := 1 to w-1 do
      begin

        if(img3[xo,yo].gradStrength  < 100) then begin
            img3[xo,yo].gradStrength := 0;
            img3[xo,yo].R := 0; img3[xo,yo].G := 0;
            img3[xo,yo].B := 0; img3[xo,yo].I := 0;
        end
        else begin
            img3[xo,yo].gradStrength := 100;
            img3[xo,yo].R := 255; img3[xo,yo].G := 255;
            img3[xo,yo].B := 255; img3[xo,yo].I := 255;
        end;

      end;

end;

procedure TForm1.Button1Click(Sender: TObject);
var xo, yo, w, h: integer;  Gvid: real;
begin
   if(Length(img1) > 0) then
     begin

       w := High(img2);
       h := High(img2[0]);

       kernel_size := StrToInt(Edit1.Text) - 1;

       CreateFilter();
       GausaFiltrs();
       SobelaOperators();
       NemaksimaloIzt();

      // for yo := 1 to h-1 do
      //  for xo := 1 to w-1 do
      // begin
      //
      //     Gvid := (   img3[xo,yo].R + img3[xo,yo].G + img3[xo,yo].B + img3[xo,yo].I ) / 4;
      //
      //    if (Gvid > 0) or (Gvid < 255) then begin
      //      img3[xo,yo].R := 0; img3[xo,yo].G := 0;
      //      img3[xo,yo].B := 0; img3[xo,yo].I := 0;
      //    end
      //end;

         Case RadioGroup1.ItemIndex of
          0: begin
               if Length(img3)>0 then
               WriteToImage(img3, Image2, 'RGB');
             end;
          1: begin
               if Length(img3)>0 then
               WriteToImage(img3, Image2, 'I');
             end;
          end;

     end;
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

