import os
import numpy as np
import dask.array as da
from tifffile import imwrite
import yaml
import argparse

from random import uniform
from time import sleep
from skimage.morphology import remove_small_objects
from skimage.measure import regionprops
from scipy.ndimage import distance_transform_edt
# from skimage.morphology import disk
# from dask_image.ndfilters import median_filter

from skimage import measure


def arg_parse():
    parser = argparse.ArgumentParser(description="Do lego measurements")
    parser.add_argument('--config', type=str, nargs=1,
                        help="Location of config file, all other arguments will be "
                             "ignored and overwriten by those in the yaml file",
                        default=None)
    parser.add_argument('--met_range', type=int, nargs=2, required=False)

    args = parser.parse_args()
    return args


def main():
    args = arg_parse()
    if args.met_range is not None:
        met_start, met_stop = args.met_range
        print(met_start)
        print(met_stop)
    else:
        print("No Met Range")

    if args.config:
        try:
            with open(args.config[0], 'r') as con:
                try:
                    processing_parameters = yaml.safe_load(con)
                except Exception as exc:
                    print(exc)

        except FileNotFoundError as exc:
            print(exc)
            exit(f"Config yml file {args.config[0]} not found, please specify")

        if not processing_parameters:
            print(f"Config file not loaded properly")

        dir1 = processing_parameters['base_directory']
        csv_file = processing_parameters['csv_file']
        raw_zarr_path = processing_parameters['raw_zarr_path']
        c1_zarr_path = processing_parameters['c1_zarr_path']
        c2_zarr_path = processing_parameters['c2_zarr_path']
        c3_zarr_path = processing_parameters['c3_zarr_path']
        seg_zarr_path = processing_parameters['seg_zarr_path']
        vessel_zarr_path = processing_parameters['vessel_zarr_path']
        z_pixels, y_pixels, x_pixels = processing_parameters['voxel_sizes']
        locThk_zarr_path = processing_parameters['locThk_zarr_path']

        if met_start is None:
            if 'met_range' in processing_parameters:
                met_start, met_stop = processing_parameters['met_range']

    else:
        csv_file = "/stornext/General/scratch/GP_Transfer/Lachie/935_all_met_mask_median3filter-lbl-morpho.csv"
        dir1 = "/vast/scratch/users/whitehead/sabrina/"
        raw_zarr_path = os.path.join(dir1, "raw_zarr_test")
        c1_zarr_path = os.path.join(dir1, "C1_zarr")
        c2_zarr_path = os.path.join(dir1, "C2_zarr")
        c3_zarr_path = os.path.join(dir1, "C3_zarr")
        seg_zarr_path = os.path.join(dir1, "seg_zarr")


        x_pixels = 1.2197 * 3
        y_pixels = 1.2197 * 3
        z_pixels = 2.8846

    voxel_volume = z_pixels * x_pixels * y_pixels # (um**3)

    all_mets = []

    print(dir1)
    print(csv_file)
    print(z_pixels, y_pixels, x_pixels)

    with open(csv_file, 'r') as f:
        print(f.readline())
        for l in f:
            line = str.split(l, ',')
            line = [int(l) for l in line]
            all_mets.append(line)

    for met in all_mets:
        met[1] = met[1] * voxel_volume

    output_dir = os.path.join(dir1, 'output_mets')

    # this is to try and prevent two jobs creating the same directory
    # don't judge me
    sleep(uniform(1,10))

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
    else:
        pass


    output = [['MET_ID', 'Volume',
               '001', '010', '011', '100', '101', '110', '111',
               'min_dist','max_dist','mean_dist','Nearest Vessel Thickness']]

    save_tiff = True
    save_full_res = True
    measure_distances = True
    skip_everything_for_testing = False

    if met_start is None:
        met_start = 0
    if met_stop is None:
        met_stop = len(all_mets)

    if met_stop > len(all_mets):
        met_stop = len(all_mets)

    print("There are %i objects detected" % len(all_mets))
    print(raw_zarr_path)
    if os.path.exists(raw_zarr_path):
        print("SHOULD WORK")
    else:
        print("Zarr path missing?!?!")

    if skip_everything_for_testing:
        pass
    else:
        c1_zarr = da.from_zarr(c1_zarr_path)
        c2_zarr = da.from_zarr(c2_zarr_path)
        c3_zarr = da.from_zarr(c3_zarr_path)
        seg_zarr = da.from_zarr(seg_zarr_path)
        raw_zarr = da.from_zarr(raw_zarr_path)
        vessel_zarr = da.from_zarr(vessel_zarr_path)
        locThk_zarr = da.from_zarr(locThk_zarr_path)


    for met in all_mets[met_start:met_stop]:
        if met[1] > 1000:

            met_num = met[0]
            met_vol = met[1]

            print("DOING MET_ID: %i" % met_num,flush=True)
            print(met)
            if not skip_everything_for_testing:
                # get coords:
                x1, x2, y1, y2, z1, z2 = met[2:]
                if z2 - z1 >= 3:
                    # raw data - big ones may kill it, tested with ~35GB MET, works
                    # if mem > 128G
                    if save_full_res:
                        roi = raw_zarr[0, :, z1:z2, 3 * y1:3 * y2, 3 * x1:3 * x2]
                        roi = roi.swapaxes(0, 1)
                        out_file = os.path.join(output_dir, 'Met_%i.tif' % met_num)
                        a = imwrite(out_file,
                                    roi[:, 0:4, :, :],
                                    resolution=(1. / x_pixels, 1. / y_pixels),
                                    metadata={'spacing': z_pixels, 'unit': 'um', 'axes': 'ZCYX'},
                                    imagej=True)

                    # get rois
                    c1_roi = c1_zarr[z1:z2, y1:y2, x1:x2]
                    c2_roi = c2_zarr[z1:z2, y1:y2, x1:x2]
                    c3_roi = c3_zarr[z1:z2, y1:y2, x1:x2]
                    seg_roi = seg_zarr[z1:z2, y1:y2, x1:x2] == met_num

                    # mask and get lego
                    c1_masked = c1_roi * seg_roi
                    c2_masked = c2_roi * seg_roi
                    c3_masked = c3_roi * seg_roi

                    c1_bin = make_binary(c1_masked, 0)
                    c2_bin = make_binary(c2_masked, 1)
                    c3_bin = make_binary(c3_masked, 2)

                    masked_sum = c1_bin + c2_bin + c3_bin
                    z_size, y_size, x_size = masked_sum.shape

                    lego = masked_sum.compute()

                    # calculate scores and store results
                    scores = []
                    for i in range(1, 8):
                        score = np.sum(lego == i)
                        scores.append(score)


                    ratio_scores = [x / np.sum(scores) for x in scores]

                    res = [met_num, met[1]]
                    for s in ratio_scores:
                        res.append(s)


                    # save TIF mask
                    if save_tiff:
                        output_im = da.zeros((7, z_size, y_size, x_size), dtype=np.uint8)
                        for c in range(1, 8):
                            ch = 255 * (lego == c)
                            output_im[c - 1, :, :, :] = ch

                        output_im = output_im.swapaxes(0,1)
                        a = imwrite(os.path.join(output_dir, 'met_%i_mask.tif' % met_num),
                                    output_im,
                                    resolution=(1. / x_pixels, 1. / y_pixels),
                                    metadata={'spacing': z_pixels,
                                              'unit': 'um',
                                              'axes': 'ZCYX'},
                                    imagej=True
                                    )
                if measure_distances:
                    w = x2 - x1
                    h = y2 - y1
                    cx = int(x1 + w / 2)
                    cy = int(y1 + h / 2)
                    search_radius = 100
                    nearby_vessels = vessel_zarr[:, cy - search_radius:cy + search_radius,
                                     cx - search_radius:cx + search_radius]
                    nearby_vessels = nearby_vessels.compute()
                    cell_in_middle = seg_zarr[:, cy - search_radius:cy + search_radius,
                                     cx - search_radius:cx + search_radius] == met_num

                    cleaned_vessels = remove_small_objects(nearby_vessels==255, min_size=1000)
                    scaled_dist_transform = distance_transform_edt(1 - cleaned_vessels,
                                                                       sampling=(z_pixels, y_pixels*3.0, x_pixels*3.0))
                    lbl = measure.label(cell_in_middle)
                    try:
                        measurements = regionprops(lbl, intensity_image=scaled_dist_transform)
                        min_dist = measurements[0].min_intensity
                        max_dist = measurements[0].max_intensity
                        mean_dist = measurements[0].mean_intensity
                    except Exception as e:
                        print(e)
                        print('no vessel within search radius')
                        min_dist = 'NA'
                        max_dist = 'NA'
                        mean_dist = 'NA'


                    # LOCAL THICKNESS
                    try:
                        nearby_locThk = locThk_zarr[:, cy - search_radius:cy + search_radius,
                                                    cx - search_radius:cx + search_radius]
                        nearby_locThk = nearby_locThk.compute()
                        filtered_locThk = cleaned_vessels * nearby_locThk
                        dist_from_cell = distance_transform_edt(1 - cell_in_middle, sampling=(z_pixels, y_pixels*3.0, x_pixels*3.0))
                        nearest_to_measure = (dist_from_cell < mean_dist) * filtered_locThk
                        loc_lbl = measure.label(nearest_to_measure > 0)
                        measurements = regionprops(loc_lbl, intensity_image=filtered_locThk)

                        closest_vessel_thickness = np.mean([m.mean_intensity for m in measurements])

                    except Exception as e:
                        #shit
                        print(e)
                        print("not sure what's going on yet")
                        closest_vessel_thickness = "dunno"

                    res.append(min_dist)
                    res.append(max_dist)
                    res.append(mean_dist)
                    res.append(closest_vessel_thickness)
                print(res)
                output.append(res)

            else:
                pass

    with open(os.path.join(output_dir,'RESULTS_met_%i_to_%i.csv' % (met_start,met_stop)), 'w') as f:
        for l in output:
            print('%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s' % (l[0],l[1],l[2],
                                                           l[3],l[4],l[5],
                                                           l[6],l[7],l[8],
                                                           l[9],l[10],l[11],l[12]
                                                           ), file=f)
    print("DONE")

def make_binary(im,binary_value):
    binVal = 2 ** binary_value
    x = binVal * (im / 255)
    return x


if __name__ == '__main__':
    main()
