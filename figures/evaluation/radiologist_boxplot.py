import matplotlib.pyplot as plt
import matplotlib as mpl
mpl.rcParams['axes.linewidth'] = 2 #set the value globally
import numpy as np
import tikzplotlib

def read(name, number=True):
    data = {}
    with open(name, 'r') as file:
        for line in file:
            values = line.strip().split('\t')
            key = values[0]
            if number:
                array = [int(x) for x in values[1:]]
            else:
                array = [x for x in values[1:]]
            data[key] = array
    return data

def resort(score_tab, shuffle_list, summary):
    
    for hum in score_tab.keys():
        order = shuffle_list[hum]
        score = score_tab[hum]
        for i,o in enumerate(order):
            summary[o].append(score[i])
    return summary

recos =['l1_pics', 'dp_nlinv', 'dp_pics', 'coil_comb']
summary={}
for reco in recos:
    summary[reco] = []

shuffle_list = read('shuffle_list', False)
score_1 = read('score_erik')
score_2 = read('score_ravi')

summary = resort(score_1, shuffle_list, summary)
summary = resort(score_2, shuffle_list, summary)

print(summary)

def boxplot(ax, stats, title, recos, ylabel, ylim):
    factor=2
    
    ax.boxplot([stats[k] for k in stats.keys()], positions=np.array(range(len(recos)))*factor, autorange=True, showmeans=True)
    
    ax.set_title(title)
    ax.set_ylabel(ylabel)
        
    ax.set_xticks(np.arange(0, len(recos) * factor, factor))
    ax.set_xticklabels(recos)
    
    ax.set_ylim(ylim)

    def set_box_color(bp, color):
        plt.setp(bp['boxes'], color=color)
        plt.setp(bp['whiskers'], color=color)
        plt.setp(bp['caps'], color=color)
        plt.setp(bp['medians'], color=color)

#    set_box_color(bpl, '#D7191C') # colors are from http://colorbrewer2.org/
    ax.grid("on")

fig, ax = plt.subplots(1, 1, figsize=(14, 10))
boxplot(ax, summary, 'Image quality evaluation by radiologist ', recos, 'Score', [1.8,5.2])
tikzplotlib.save("stats.tex")
