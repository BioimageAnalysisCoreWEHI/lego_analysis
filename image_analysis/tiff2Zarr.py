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

    if not os.path.exists(os.path.join(out_path,'.zarray')):
        z = tiff2Zarr(fpath,
                      out_path,
                      block_size_max=chunk_limit)
    else:
        pass


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


if __name__ == '__main__':
    main()
