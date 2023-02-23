from spreco.common import utils
from spreco.workbench.trainer import trainer
import argparse

def main(folder, model_name, exported_folder, exported_name):
    config_file = folder+'/config.yaml'

    try:
        config           = utils.load_config(config_file)
        config['gpu_id'] = '2'
    except:
        raise Exception("Loading config file failed, please check if it exists.")

    config['batch_size'] = 1
    insw = trainer(None, None, config)

    insw.export(folder+'/'+model_name, exported_folder, exported_name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--folder', metavar='path', default='/home/gluo/workspace/nlinv_prior/logs/pixelcnn_abide_300', help='')
    parser.add_argument('--model_name', metavar='path', default='pixelcnn_60', help='')
    parser.add_argument('--exported_folder', metavar='path', default='/home/gluo/workspace/nlinv_prior/logs/exported', help='')
    parser.add_argument('--exported_name', metavar='path', default='pixelcnn_abide_300', help='')
    args = parser.parse_args()
    main(args.folder, args.model_name, args.exported_folder, args.exported_name)