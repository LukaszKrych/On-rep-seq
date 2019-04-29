rule getLCPs:
	input:
		"data/01_porechopped_data/{barcode}.fastq"
	output:
		"data/02_LCPs/{barcode}.txt",
	params:
		"data/02_LCPs"
	shell:
		"""
		cat {input} | awk '{{if(NR%4==2) print length($1)+0}}' | sort -n | uniq -c | sed "s/   //g" |  sed "s/  //g" | sed "s/^ *// " > {output}
		"""
rule plotLCPs:
	input:
		expand("data/02_LCPs/{barcode}.txt", barcode=BARCODES)
	output:
		pdfResults="data/02_LCPs/LCP_plots.pdf"		
	run:
		#import libraries
		import matplotlib.pyplot as plt
		import numpy as np
		import math
		
		#set subplot features	
		filelist=sorted(input, key=lambda x: int(x.split('BC')[1].split(".")[0]))
		nro=math.ceil(len(filelist)/3)
		fig, axes = plt.subplots(nrows=nro, ncols=3, figsize=(12, 50), 
			sharex=True, sharey=True)
		plt.xlim(0,3500)

		#plot each barcode
		i = 0
		for row in axes:
			for ax in row:
				if i < len(filelist):
					if os.path.getsize(filelist[i]) > 10:
						data=np.loadtxt(filelist[i])
						X=data[:,0]
						Y=data[:,1]
					else:
						X=0
						Y=0

					ax.plot(Y, X)
					#add label to barcode subplot
					ax.text(0.9, 0.5, filelist[i].split("/")[-1].split(".")[0],
						transform=ax.transAxes, ha="right")
					
					i += 1
		#save figure to pdf				
		fig.savefig("data/02_LCPs/LCP_plots.pdf", bbox_inches='tight')

rule peakPicker:
	input:
		"data/02_LCPs/{barcode}.txt"
	output:
		"data/03_LCPs_peaks/peaks_{barcode}.txt"
	conda:
		"envs/R.yaml"
	shell:
		"""
		Rscript --vanilla scripts/peakpicker.R -f {input} -o {output} -v TRUE || true 
		touch {output}
		"""
rule LCPsCluster:
	input:
		expand("data/02_LCPs/{barcode}.txt", barcode=BARCODES)
	output:
		html="data/02_LCPs/LCP_clustering_heatmaps.html",
		directory=temp("data/02_LCPs/txt")
	params:
		html="runnable_jupyter_on-rep-seq_flowgrams_clustering_heatmaps.html",
		directory="data/02_LCPs"
	conda:
		"envs/R.yaml"
	shell:
		"""
		cp {params.direct}/*txt {output.directory}
		find {output.directory} -size 0 -delete
		Rscript -e "IRkernel::installspec()"
		./scripts/LCpCluster.R {output.directory} {params.html}
		mv {params.html} {output.html}
		"""

