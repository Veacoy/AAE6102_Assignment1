% 示例数据
[x, y] = meshgrid(-3:0.1:3, -3:0.1:3);
z = exp(-x.^2 - y.^2) .* cos(3*x).^2;  % 构造一个有峰值的函数

% 绘制三维峰值图
surf(x, y, z);
shading interp;         % 插值平滑
colormap(jet);          % 颜色映射
colorbar;               % 添加颜色条
title('3D Peak Map (Surface Plot)');
xlabel('X');
ylabel('Y');
zlabel('Z');
