rule demultiplexing_1:
    input:
        BASECALLED_DIR
    output:
        temp(expand(OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq_01", barcode=BARCODES))
    params:
        output_dir=OUTPUT_DIR + "/01_porechopped_data"
    conda:
        "envs/On-rep-seq.yaml"
    message:
        "Demultiplexing step 1"
    threads: 16
    shell:
        """ 
        counter=1
        n=$(ls -l {input}/*fastq | wc -l )
        rm -f {params.output_dir}/*fastq
        for filename in {input}/*fastq
        do
            echo "Processing sample $counter/$n"
            porechop -i $filename -b dir_$filename -t {threads} --discard_unassigned --verbosity 0 > /dev/null 2>&1
            for bar in dir_$filename/*.fastq
            do
                f=$(basename -- $bar)
                cat $bar >> {params.output_dir}/$f
            done  
            rm -rf dir_$filename
            counter=$((counter+1))
        done
        line=$(echo {BARCODES})
        for barcode in $line
        do
            touch {params.output_dir}/$barcode.fastq
            mv {params.output_dir}/$barcode.fastq {params.output_dir}/$barcode.fastq_01
        done
        """

rule demultiplexing_2:
    input:
        OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq_01" 
    output:
        OUTPUT_DIR + "/01_porechopped_data/{barcode}.fastq"
    conda:
        "envs/On-rep-seq.yaml"
    shell:
        """
        if [ -s {input} ];
        then
            porechop -i {input} -o {output} --fp2ndrun
        else
            touch {output}
        fi

        """