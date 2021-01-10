clear all ;close all ;clc;


%%Chargement les images
filename = cell(0); 
filename = {...
	'../data/1.png';...
	'../data/2.png';...
    %'../data/1.jpg';...
    %'../data/2.jpg';...
	};
imgNum = length(filename);
img = cell(imgNum,1);
for p = 1:imgNum
	img{p} = imread(filename{p}); 
	[mrows(p), ncols(p), dim] = size(img{p});
	figure(p), imshow(img{p}), title(['image',num2str(p)]);
end

%%Choisir les points
 % les points par raports les images arriere
x1ctrl = cell(0); 
y1ctrl = cell(0); 
 % les points par raports les images dernier 
x2ctrl = cell(0);
y2ctrl = cell(0); 

for p = 1:imgNum
	if p ~= 1
		figure(p), hold on;
		title(['image',num2str(p),'£ºchoisir ',num2str(ctrlLen),' points']); 
		x2ctrl{p} = []; y2ctrl{p} = [];
		for q = 1:ctrlLen
			[x2 y2 button] = ginput(1);
			x2ctrl{p} = [x2ctrl{p};x2]; 
			y2ctrl{p} = [y2ctrl{p};y2];
			plot(x2,y2,'ro');
			text(x2+3,y2,num2str(q));
		end
	end

	if p ~= imgNum
		figure(p), hold on;
		title(['image',num2str(p),'£ºchoisir au moins 3 points , taper "touche de entr¨¦e" pour arrter ']);
		x1ctrl{p} = []; y1ctrl{p} = [];
		ctrlLen = 0;
		while 1
			[x1 y1 button] = ginput(1);
			if isempty(x1) break; end
			ctrlLen = ctrlLen+1;
			x1ctrl{p} = [x1ctrl{p};x1];
			y1ctrl{p} = [y1ctrl{p};y1];
			plot(x1,y1,'go');
			text(x1+3,y1,num2str(ctrlLen));
		end
	end
end
 save ctrls.mat x1ctrl y1ctrl x2ctrl y2ctrl
% load ctrls.mat  % on peut utiliser le mat directement 




%%Homographie(affine) 
H1toP1 = eye(3); 
for p = 1:imgNum-1
	A = [x1ctrl{p},y1ctrl{p},ones(length(x1ctrl{p}),1)];
	row1 = A\x2ctrl{p+1};
	row2 = A\y2ctrl{p+1};
	H = [row1';row2';[0 0 1]]; % H(p a p+1)
	H1toP1 = H1toP1*H; % H(1 a p+1)
	Hinv = inv(H1toP1); % H(img(p+1) a img(1))

    
    %% Projection de pixels
	pt = zeros(3,4); % garder les coordinnes des 4 points de cornes 
	pt(:,1) = Hinv*[1;1;1]; % En haut ¨¤ gauche
	pt(:,2) = Hinv*[ncols(p+1);1;1]; % En haut ¨¤ droite
	pt(:,3) = Hinv*[ncols(p+1);mrows(p+1);1]; % En bas ¨¤ droite
	pt(:,4) = Hinv*[1;mrows(p+1);1]; % En bas ¨¤ gauche
    
    % eviter le coodonnes negatives
    Xoffset = 0; Yoffset = 0; 
	up = round(min(pt(2,:)));
	if up <= -Yoffset
		img{1} = [zeros(-Yoffset-up+1,size(img{1},2),dim);img{1}]; 
		Yoffset = -up+1;
	end
	down = round(max(pt(2,:)));
	
	left = round(min(pt(1,:)));
	if left <= -Xoffset
		img{1} = [zeros(size(img{1},1),-Xoffset-left+1,dim);img{1}];
		Xoffset = -left+1;
	end
	right = round(max(pt(1,:)));
    
    
    
    % verifier le zone pour l'image2
	if right > size(img{1},2) || down > size(img{1},1)
 		img{1}(max(down,size(img{1},1)),max(right,size(img{1},2)),1) = 0; 
     end
	
    
    
    % parcourir et projection 
    % (q,r) est le point de pixel 
	for r = up:down
		for q = left:right       
			pto = H1toP1*[q;r;1];
			Xo = pto(1);Yo = pto(2);
			if Xo<1 || Yo<1 || Xo>ncols(p+1) || Yo>mrows(p+1)
				continue;
			end
			img{1}(r+Yoffset,q+Xoffset,:) = img{p+1}(round(Yo),round(Xo),:); %×î½üÁÚ²åÖµ
		end
	end
	
end

figure,imshow(img{1}),title('resultat');
