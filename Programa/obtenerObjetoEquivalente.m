function [objeto_out, nuevo_objeto, objeto_usado] = ...
    obtenerObjetoEquivalente(objeto_in, lista_objetos)

objeto_usado = 0;
cantidad_objetos_reales = size(lista_objetos,2);
if not(isempty(lista_objetos))
    for i=1:cantidad_objetos_reales
        distancia = sqrt((objeto_in.Centroid(1) - ...
            lista_objetos(i).Centroid(1))^2 + (objeto_in.Centroid(2)...
            -lista_objetos(i).Centroid(2))^2);
        
        if distancia < lista_objetos(i).EquivDiameter/5 && ...
                not(lista_objetos(i).Reemplazado)
            
            objeto_out = objeto_in;
            objeto_out.Etiqueta = lista_objetos(i).Etiqueta;
            objeto_out.Precision = lista_objetos(i).Precision;
            objeto_out.Tracking = lista_objetos(i).Tracking;
            objeto_out.Util = 1;
            nuevo_objeto = 0;
            objeto_usado = i;
            if not(strcmp(objeto_out.Etiqueta,' ')) && ...
                    not(strcmp(lista_objetos(i).Etiqueta,' '))
                return
            end
        end
    end
end 

if not(objeto_usado)
    objeto_out = objeto_in;
    nuevo_objeto = 1;
end

