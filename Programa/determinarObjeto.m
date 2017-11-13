function objeto = determinarObjeto(frame,im1,im2,im3,puntos_plantillas)
%% SIFT
[im, descriptors, locs] = sift(frame);

%% MATCH
if size(descriptors,1)
    num1 = match(im, descriptors, locs,im1, ...
        puntos_plantillas.descriptors1, puntos_plantillas.locs1); 
    num2 = match(im, descriptors, locs,im2, ...
        puntos_plantillas.descriptors2, puntos_plantillas.locs2);
    num3 = match(im, descriptors, locs,im3, ...
        puntos_plantillas.descriptors3, puntos_plantillas.locs3);
    ganador = max([num1,num2,num3]);
else
    ganador = 0;
end
if ganador < 5
    ganador = 0;
end

%% GANADOR
switch ganador
  case 0
      objeto = ' ';
  case num1
      objeto = 'LOGOTIPO';
  case num2
      objeto = 'TELEFONO1';
  case num3
      objeto = 'TELEFONO2';
end