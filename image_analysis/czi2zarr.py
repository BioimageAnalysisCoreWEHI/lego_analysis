import numpy as np
import os
from aicsimageio import AICSImage
from aicspylibczi import CziFile
import dask.array as da
from dask import delayed
from dask.diagnostics import ProgressBar
import argparse

def main():
    args = arg_parse()

    fpath = args.input[0]
    out_path = args.output[0]
    chunk_limit = args.chunk_limit

    if not os.path.exists(out_path):
        os.mkdir(out_path)

    print(args)

    if os.path.exists(os.path.join(out_path,'.zarray')):
        print("Zarr already exists - won't bother doing it again")
    else:
        z = czi2zarr(fpath,
                      out_path)



def arg_parse():
    parser = argparse.ArgumentParser(description="Convert tif to zarr")
    parser.add_argument('--input',
                        type=str,
                        nargs=1,
                        help="Input tif file",
                        required=True)
    parser.add_argument('--output',
                        type=str,
                        nargs=1,
                        help="Output file location",
                        required=True)
    parser.add_argument('--chunk_limit',
                        type=float,
                        required=False,
                        default=1e8
                        )

    args = parser.parse_args()
    return args



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


if __name__ == '__main__':
    main()
