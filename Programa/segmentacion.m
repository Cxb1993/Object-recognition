function frame_segmentado = segmentacion (imagen_rgb)


%% VARIABLES
umbral = 80000000; %% Los brillos alcanzan unos 12000 y los folios 14000
% Canal RGB
imagen_B = im2double(imagen_rgb(:,:,3));
% Canal YCBCR
imagen_ycbcr = rgb2ycbcr(imagen_rgb);
% Histograma
% histograma_imagen_B = histogram(imagen_B,255);
cantidad_blanco = 0;
% for i=150:255
%     cantidad_blanco = cantidad_blanco + histograma_imagen_B.Values(1,i);
% end
%% SEGMENTACION INICIAL
if cantidad_blanco > umbral
    %% SEGMENTACION CON FOLIO
    % Se eliminan los colores blancos puros (folios)
    imagen_restada = imagen_ycbcr(:,:,2) - imagen_ycbcr(:,:,1);
    % Se potencian los colores resultantes (objetos + entorno)
    imagen_multiplicada = 10*imagen_restada;
    % Se binariza
    imagen_bw = im2bw(imagen_multiplicada);
else
    %% SEGMENTACION SIN FOLIO
    % Se obtienen los canales deseados:
    imagen_Cb = im2double(imagen_ycbcr(:,:,2));
    imagen_Cb_eq = imadjust(imagen_Cb,[0.4;0.6],[0;1]);
    imagen_R = im2double(imagen_rgb(:,:,1));
    % Se operan las imágenes
    imagen_B = imagen_B-imagen_R;
    % Se potencian todos los azules
    imagen_potenciada = imagen_Cb_eq .* imagen_B;
    imagen_bw = im2bw(imadjust(imagen_potenciada,[0;0.5],[0;1],0.2));
end

%% SEGMENTACION FINAL
% frame_close_menor_2 = imclearborder(imagen_bw);
frame_close_menor_3 = bwareaopen(imagen_bw,300);
SS = strel('diamond',20);
frame_close_2 = imclose(frame_close_menor_3,SS);
SE = strel('disk',5);
frame_segmentado = imdilate(frame_close_2,SE);








