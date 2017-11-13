
%%%%%%%%%%%%%%%%%%%%%%%% ¿QUE HACE ESTA FUNCION? %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   -Fucnion principal del procesado del video reconocimiento y seguimiento

clc; 

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --> Video
vidObj = cargarVideo;
% --> Plantillas
[im1,im2,im3] = cargarPlantillas;
% --> Declaracion de otras Variables
frame = zeros(vidObj.Height,vidObj.Width,3,'uint8');
frame_ini = 1;
frame_fin = vidObj.NumberOfFrames;
ratio = 0.5;
lista_objetos_reales = [];
precision_deseada = 11;
precision_inferior = -20;
global stop modo_ejecucion disp_segmentacion 
disp_segmentacion_anterior = 1;
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROCESADO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --> PLANTILLAS
% SIFT
puntos_plantillas = load ('puntosSIFTPlantillas.mat');
im1 = rgb2gray(im1);
im2 = rgb2gray(im2);
im3 = rgb2gray(im3);

% --> VIDEO
for i=frame_ini:5:frame_fin
    t_frame = tic;
    hold off;
    
    %% CAPTACION DEL FRAME
    frame = imresize(read(vidObj,i),ratio);
    
    %% SEGMENTACION DE LA IMAGEN
    frame_segmentado = segmentacion (frame);
    
    
    %% OBSERVACION DE LOS OBJETOS EN EL NUEVO FRAME
    lista_objetos = regionprops(frame_segmentado,'Centroid','Area',...
        'EquivDiameter','BoundingBox');
    if not(isempty(lista_objetos))
        for n=1:size(lista_objetos,1)
            lista_objetos(n).Etiqueta = ' ';
            lista_objetos(n).Util = 1;
            lista_objetos(n).Reemplazado = 0;
            lista_objetos(n).Precision = 0;
            lista_objetos(n).Tracking = [];
        end
    end
    cantidad_objetos_detectados = size(lista_objetos,1);
    
    %% SE PONE LA UTILIDAD DE LOS OBJETOS DEL FRAME ANTERIOR A CERO
    if not(isempty(lista_objetos_reales))
        for n=1:size(lista_objetos_reales,2)
            lista_objetos_reales(n).Util = 0;
        end
    end
    
    %% SE ANALIZAN LOS OBJETOS NUEVOS DEL FRAME NUEVO
    if not(isempty(lista_objetos))
        for n=1:cantidad_objetos_detectados
            %% SE OBTIENE EL OBJETO EQUIVALENTE DEL FRAME ANTERIOR
            [lista_objetos(n), nuevo_objeto, objeto_copiado] = ...
                obtenerObjetoEquivalente(lista_objetos(n),...
                lista_objetos_reales);
            %% SE INUTILIZA EL OBJETO ANTIGUO QUE YA HA SIDO COPIADO
            if objeto_copiado
                lista_objetos_reales(objeto_copiado).Reemplazado = 1;
                if ~strcmp(lista_objetos_reales(objeto_copiado).Etiqueta...
                        ,' ')
                    lista_objetos(n).Tracking(end+1,:) = ...
                        lista_objetos(n).Centroid;
                end
            end
            %% Si se cumplen las condiciones --> SE ANALIZA EL OBJETO
            if nuevo_objeto ||...
                    (lista_objetos(n).Precision < precision_deseada &&...
                    lista_objetos(n).Precision > precision_inferior) ||...
                    (not(mod(i,20)) && lista_objetos(n).Precision < 30)
                
                % Se analiza con SIFT
                objeto_crop = imcrop(frame, lista_objetos(n).BoundingBox);
                etiqueta_anterior = lista_objetos(n).Etiqueta;
                lista_objetos(n).Etiqueta =...
                    determinarObjeto(objeto_crop, im1, im2, im3, ...
                    puntos_plantillas);
                
                % Contabilizar la precision de la deteccion
                if strcmp(etiqueta_anterior,lista_objetos(n).Etiqueta)&&...
                        not(strcmp(lista_objetos(n).Etiqueta,' '))
                    lista_objetos(n).Precision = ...
                        lista_objetos(n).Precision + 10;
                elseif strcmp(etiqueta_anterior,' ')...
                        && not(strcmp(lista_objetos(n).Etiqueta,' '))...
                        && lista_objetos(n).Precision < precision_deseada
                    lista_objetos(n).Precision = 0;
                else
                    lista_objetos(n).Precision = ...
                        lista_objetos(n).Precision - 1;
                    lista_objetos(n).Etiqueta = etiqueta_anterior;
                end
            end
            if lista_objetos(n).Precision < 0
                lista_objetos(n).Etiqueta = ' ';
            end
            
            %% Se introduce el objeto real comprobado en la lista de reales
            if isempty(lista_objetos_reales)
                lista_objetos_reales = lista_objetos(n);
            else
                lista_objetos_reales(end+1) = lista_objetos(n);
            end
        end
    end
    
    %% ELIMINACION DE OBJETOS INUTILES EN LA ESCENA
    if not(isempty(lista_objetos_reales))
        for n=size(lista_objetos_reales,2):-1:1
            if lista_objetos_reales(n).Util == 0
                lista_objetos_reales(n) = [];
            end
        end
    end
    
    %% RECUADRAR LOS OBJETOS DETECTADOS Y COMPROBADOS
    if not(isempty(lista_objetos_reales))
        for n=1:size(lista_objetos_reales,2)
            if ~strcmp(lista_objetos_reales(n).Etiqueta ,' ')
                if lista_objetos_reales(n).Precision >= precision_deseada
                    color = 'green';
                else
                    color = 'yellow';
                end
                etiqueta = cat(2,lista_objetos_reales(n).Etiqueta,' ',...
                    num2str(lista_objetos_reales(n).Precision));
                frame = insertObjectAnnotation(frame,'rectangle',...
                    lista_objetos_reales(n).BoundingBox,...
                    etiqueta,'Color',color);
            end
        end
    end
    
    %% DIBUJAR

    if ~disp_segmentacion
        image(frame);axis off image; hold on;
        FPS = 1/toc(t_frame);
        text(10,18,num2str(FPS),'Color','white','FontSize',15);
        if modo_ejecucion == 2
            if not(isempty(lista_objetos_reales))
                for n=size(lista_objetos_reales,2):-1:1
                    if not(isempty(lista_objetos_reales(n).Tracking))
                        plot(lista_objetos_reales(n).Tracking(:,1),...
                            lista_objetos_reales(n).Tracking(:,2));
                    end
                end
            end
        end
    else
        subplot(2,1,1);
        image(frame);axis off image;
        hold on;
        FPS = 1/toc(t_frame);
        text(10,18,num2str(FPS),'Color','white','FontSize',15);
        subplot(2,1,2);
        imshow(frame_segmentado);
    end
    drawnow;
    disp_segmentacion_anterior = disp_segmentacion;
    if stop
        stop = 0;
        msgbox('Programa Finalizado','STOP','Warn');
        return;
    end
end


