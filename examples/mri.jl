using MAT

D = matread("mri.mat")
vol = dropdims(D["D"], dims=3)

using GR

for slice in 1:27
    imshow(255 .- vol[:, : , slice], colormap=GR.COLORMAP_BONE)
end
