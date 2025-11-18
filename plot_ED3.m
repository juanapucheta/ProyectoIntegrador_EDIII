%% Visualización de Datos por Comunicación Serie (Tx & Rx)
function varargout=ADQ_PIC16F887(varargin)

global tiempo data num SerialP parar

parar = true;     % No inicia lectura hasta apretar INICIAR Rx
ready=true;
start=0;

%% ============================
%   CONFIGURACIÓN DE LA FIGURA
% =============================
fig(1)=figure('name','EDII','menubar','none','position',[200 220 800 700],'color',[0 0 0]);
movegui(fig(1),'center'); 
screenSize = get(0, 'ScreenSize');
set(fig(1), 'Position', screenSize);

axe(1)=axes('parent',fig(1),'units','pixels',...
    'position',[110 120 1300 480], 'xlim',[0 80],'ylim',[0 40], ...
    'XColor',[1 1 1],'YColor',[1 1 1],'xgrid','on','ygrid','on',...
    'GridColor',[0.2 0.2 0.2],'fontsize',15);

set(get(axe(1),'XLabel'),'String','Tiempo (seg)','Color', [1 1 1],'fontsize',20);
set(get(axe(1),'YLabel'),'String','Cuentas AD (-)','Color', [1 1 1],'fontsize',20);

lin(1)=line('parent',axe(1),'xdata',[],'ydata',[],'Color','m','LineWidth',4);

bot(1)=uicontrol('parent',fig(1),'style','pushbutton','string','INICIAR Rx',...
    'position',[110 680 160 50],'BackgroundColor',[0 0.8 0],...
    'callback',@start_rx_button,'fontsize',17);

bot(2)=uicontrol('parent',fig(1),'style','pushbutton','string','DETENER Rx',...
    'position',[110 620 160 50],'BackgroundColor',[1 0 0],...
    'callback',@stop_rx_button,'fontsize',17);

bot(3)=uicontrol('parent',fig(1),'style','pushbutton','string','INICIAR Tx',...
    'position',[290 680 160 50],'BackgroundColor',[0 0.8 0],...
    'callback',@start_tx_button,'fontsize',17);

bot(4)=uicontrol('parent',fig(1),'style','pushbutton','string','DETENER Tx',...
    'position',[290 620 160 50],'BackgroundColor',[1 0 0],...
    'callback',@stop_tx_button,'fontsize',17);

txbx(1)=uicontrol('parent',fig(1),'style','text','string','AD',...
    'position',[1255 530 150 60],'fontsize',28,'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 0]);

%% ==========================
%     CALLBACKS DE BOTONES
% ==========================
function start_rx_button(~,~)
    parar = false;
end

function stop_rx_button(~,~)
    parar = true;
end

function start_tx_button(~,~)
    if strcmp(SerialP.Status, 'open')
        fwrite(SerialP, 1, 'uint8'); 
        disp('Comando enviado: 1');
    else
        disp('Puerto no disponible');
    end
end

function stop_tx_button(~,~)
    if strcmp(SerialP.Status, 'open')
        fwrite(SerialP, 2, 'uint8'); 
        disp('Comando enviado: 2');
    else
        disp('Puerto no disponible');
    end
end

%% ===============================
%    CONFIGURACIÓN PUERTO SERIAL
% ===============================
fclose('all');
delete(instrfindall);

info = instrhwinfo('serial');
lista = info.SerialPorts;

if isempty(lista)
    disp('No se detectaron puertos COM');
    return;
end

puerto = lista{1};
disp(['Conectando al puerto: ' puerto]);

SerialP = serial(puerto, ...
    'BaudRate', 115200, ...
    'DataBits', 8, ...
    'StopBits', 1, ...
    'Parity', 'none', ...
    'Terminator', 'LF');

fopen(SerialP);

disp('Puerto serial abierto correctamente');
start = 1;

%% ================================
%   INICIALIZACIÓN DE VECTORES
% ================================
tiempo = 0;
data   = 0;

data_limx = [0 80];
data_limy = [0 1023];

set(axe(1),'xlim',data_limx,'ylim',data_limy);

k = 1;
t0 = tic;   % Tiempo real desde inicio

%% ======================
%       BUCLE PRINCIPAL
% ======================
while start
    pause(0.01);

    if ~parar && SerialP.BytesAvailable > 0
        
        % Lectura ASCII
        lineStr = fgetl(SerialP);
        num = str2double(lineStr);

        if isnan(num)
            continue;
        end

        if ~ishandle(txbx(1))
            disp('La ventana fue cerrada. Finalizando ejecución...');
            break;
        end

        set(txbx(1),'String', sprintf('%d', num));

        % Tiempo real
        t = toc(t0);

        tiempo = [tiempo t];
        data   = [data num];

        % Actualizar gráfica
        set(lin(1),'xdata',tiempo,'ydata',data);

        % Ajuste dinámico
        % Ajuste dinámico (PARA MOSTRAR TODO EL HISTORIAL)
        if t >= data_limx(2)
        % Aquí necesitas decidir cuánto quieres que crezca. Si el límite
        % inicial es 80, y t>80, puedes expandirlo en 10.
        data_limx = [data_limx(1) data_limx(2) + 10];
        set(axe(1),'xlim',data_limx);
        end

        if num >= data_limy(2)
            data_limy = [0 data_limy(2) + 5];
            set(axe(1),'ylim',data_limy);
        end

        k = k + 1;
    end
end

end
