import numpy as np
from aicsimageio import AICSImage
from aicspylibczi import CziFile
import dask.array as da
from dask import delayed
from dask.diagnostics import ProgressBar


from skimage import measure
def get_mosaic_dask(img, channels, nz, singleChannel=False) -> da.Array:
    # read first image to get the size
    sample = img.read_mosaic(C=0, scale_factor=1, Z=0)
    sample = np.squeeze(sample)
    sample = np.squeeze(sample)
    # Create a delayed function for reading from mosaic
    delayed_mosaic_read = delayed(CziFile.read_mosaic)
    # create an array
    if not singleChannel:
        lazy_arrays = [delayed_mosaic_read(img, C=ch, Z=z, scale_factor=1) for ch in range(channels) for z in range(nz)]
    else:
        lazy_arrays = [delayed_mosaic_read(img, C=channels, Z=z, scale_factor=1) for z in range(nz)]

    mosaic_dask_array = [da.from_delayed(delayed_reader, shape=sample.shape, dtype=sample.dtype)
                         for delayed_reader in lazy_arrays]

    # mosaic_array
    # reshaping arrays results in issues reading the individual slices
    mosaic_dask_stack = da.stack(mosaic_dask_array, axis=0)  # .reshape(channels,nz,11718,8289)
    return AICSImage(mosaic_dask_stack)


def czi2zarr(fpath, outpath, chunksize_denominator=(10, 10, 10)):
    czi_data = CziFile(fpath)
    c_size = max(czi_data.get_dims_shape()[0]['C'])
    z_size = max(czi_data.get_dims_shape()[0]['Z'])
    sample = czi_data.read_mosaic(C=0, scale_factor=1, Z=0)
    x_size, y_size = sample.shape[2:]

    chunk_z, chunk_y, chunk_x = chunksize_denominator
    print("Opening %s" % fpath)

    for c in range(c_size):
        thisChannel = get_mosaic_dask(czi_data, c, z_size, singleChannel=True)  # c was = 0?
        thisChannel = da.rechunk(thisChannel.dask_data,
                                 (-1, -1, int(z_size / chunk_z), int(y_size / chunk_y), int(x_size / chunk_x)))
        if (c == 0):
            x = thisChannel
        else:
            x = da.append(x, thisChannel, axis=1)

    print("Saving to %s" % outpath)
    with ProgressBar(dt=.5):
        da.to_zarr(x, outpath, overwrite=True)

    x = da.from_zarr(outpath)

    return x


def tiff2Zarr(fpath,
              outpath,
              block_size_max=1e8):

    if not os.path.exists(outpath):
        os.mkdir(outpath)

    im = AICSImage(fpath).dask_data
    im = im.rechunk(block_size_limit=block_size_max)
    im = im[0, 0, :, :, :]
    with ProgressBar(dt=0.5):
        da.to_zarr(im, outpath, overwrite=True)

    im = da.from_zarr(outpath)
    return im

