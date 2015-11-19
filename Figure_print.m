function [error] = Figure_print(figure, type, width, height, res, file)

error = 0;
switch type
    case 'pdf'
        set(gcf,'paperunits','inches');
        set(gcf,'papersize',[width,height]) 
        print(figure, '-dpdf', ['-r' num2str(res)], file);        
    case 'jpeg'
        set(gcf,'PaperUnits','inches');
        set(gcf,'PaperPositionMode', 'auto')      
        print(figure,'-djpeg', ['-r' num2str(res)], file);
    case 'eps'
        print(figure,'-depsc', ['-r' num2str(res)], file);
    otherwise
        error = 1;
        display('ERROR:  File type not known.');
end