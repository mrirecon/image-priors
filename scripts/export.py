from spreco.common import utils
from spreco.workbench.trainer import trainer

model_path  = '/home/gluo/workspace/nlinv_prior/logs/pixelcnn_abide'
config_file = model_path+'/config.yaml'

try:
    config           = utils.load_config(config_file)
    config['gpu_id'] = '2'
except:
    raise Exception("Loading config file failed, please check if it exists.")

config['batch_size'] = 1
insw = trainer(None, None, config)

export_path = '/home/gluo/workspace/nlinv_prior/logs/exported'
insw.export(model_path+'/pixelcnn_60', export_path, 'pixelcnn_abide')