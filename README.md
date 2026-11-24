# Santali (Ol Chiki) Tesseract training

This repository holds everything needed to train `sat.traineddata` from scratch: corpus, fonts, line ground truth and scripts. The model is in [tessdata_contrib/sat](https://github.com/tesseract-ocr/tessdata_contrib/tree/main/sat).

## Requirements

- Tesseract 5 with the training tools (`lstmtraining`, `combine_lang_model`, `combine_tessdata`, `unicharset_extractor`)
- Python 3 with Pillow and NumPy
- curl

## Steps

Run each step from the repository root:

```bash
./01-prep-base.sh
python3 render-corpus.py
./02-make-lstmf.sh
./03-train.sh > logs/train.log 2>&1
./04-package.sh
python3 tools/benchmark.py --model output/sat.traineddata
```

`01-prep-base.sh` downloads `Latin.traineddata` from [tessdata_best](https://github.com/tesseract-ocr/tessdata_best) and builds the Ol Chiki base. It writes only inside the repository.

`03-train.sh` fine-tunes from Latin in one run, for 30,000 iterations. Set `MAX_ITERATIONS` to change that. Stop it with Ctrl+C and run it again to resume.

`tools/benchmark.py` reads the held-out lines and reports the character and word error rates.

## Training data

`02-make-lstmf.sh` builds `lstmf/list.txt` from:

| Type | Lines |
|------|-------|
| Scanned lines in `ground-truth/`, from 14 pages | 360 |
| Synthetic lines, 60 in each of 4 font styles | 240 |
| Synthetic lines with blur, noise, contrast changes and slight rotation | 100 |

The 142 lines in `ground-truth-heldout/` aren't trained on. They come from the 5 pages in `test-images/heldout.txt`. These are one page each of *Ajay Gada*, *Gānāṁ ār ciṭhi sākām*, *Guru Gomke* and *Rar Sanes*, and page 6 of the Raghunath Murmu article. No synthetic line shares a run of four words with them.

## Results

Tested on the 142 lines in `ground-truth-heldout/` with `tools/benchmark.py --psm 13`:

| Model | CER | WER | Spaces found | CER without spaces |
| --- | --- | --- | --- | --- |
| This recipe, 30,000 iterations | 13.8% | 32.6% | 98.9% | 15.7% |
| Run7 (earlier `sat`) | 21.2% | 100.0% | 0.1% | 6.5% |
| Indic OCR `sat` | 28.8% | 99.9% | 0.0% | 16.2% |

Run7 was trained on these 142 lines, so its figure without spaces is too low. It never wrote a space, so almost every word was wrong.

## Adding pages

1. Scan the page and type its text into a `.gt.txt` file, one printed line per line.
2. Run `python3 06-split-page.py page.png page.gt.txt --prefix name`.
3. Check the line images and text in `ground-truth/`.
4. Run `./02-make-lstmf.sh` and `./03-train.sh` again.

Keep some pages out of `ground-truth/` to test on.

## Contents

| Path | Purpose |
|------|---------|
| `corpus/sat_corpus.txt` | Santali text for the synthetic lines |
| `corpus/sat_corpus2_clean.txt` | More Santali text, not used in this run |
| `fonts/` | Guru Gomke and Noto Sans Ol Chiki, with their licences |
| `ground-truth/` | Scanned line images and their text, for training |
| `ground-truth-heldout/` | Scanned line images and their text, for testing |
| `test-images/` | The 19 scanned pages and their text |
| `linebox.py` | Writes line box files and `.lstmf` files |
| `make-list.py` | Picks the lines for `lstmf/list.txt` |
| `render-corpus.py` | Renders the corpus into line images |
| `06-split-page.py` | Splits a scanned page into line images |
| `clean-corpus.py` | Removes Latin letters and other non-Ol Chiki characters |
| `tools/augment-synthetic.py` | Adds blur, noise, contrast changes and slight rotation |
| `tools/benchmark.py` | Measures error rates on line or page images |
| `tools/check-plateau.sh` | Shows when training stops improving |

## Sources

The scanned pages come from Santali Wikisource books under CC BY-SA 4.0. They are *ᱜᱟᱱᱟᱝ ᱟᱨ ᱪᱤᱴᱷᱤ ᱥᱟᱠᱟᱢ (Gānāṁ ār ciṭhi sākām)* (2008) by Hajam Baskey, *Guru Gomke* (2004), *Ajay Gada* (2022), *Rar Sanes* and *Sahayinon* (2021). Pages `p1` to `p6` are the Santali Wikisource article on [Pandit Raghunath Murmu](https://w.wiki/D$AN), printed and scanned on a flatbed by Subhashish Panigrahi.

Corpus text, all CC BY-SA 4.0:

- Chapter 1 of [OpenSpeaks](https://en.wikiversity.org/wiki/OpenSpeaks/sat) by Subhashish Panigrahi, translated into Santali by R Ashwani Banjan Murmu, Fagu Baskey and Joy Sagar Murmu
- Santali Wikisource article on [Pandit Raghunath Murmu](https://w.wiki/D$AN)
- [Community Language Documentation & Archiving Training](https://w.wiki/ReCS), translated by Bodi Baski

Fonts, both under the SIL Open Font License:

- Guru Gomke, designed by Pooja Saxena for the Centre for Internet and Society (2014)
- Noto Sans Ol Chiki, by the Noto Project Authors

## Credits

Subhashish Panigrahi trained the model. Ramjit Tudu guided the choice of Wikisource books and shared background on earlier Santali OCR work. Prasanta Hembram tested interim models and advised during training.

## Licence

Code: Apache 2.0, the same as Tesseract. Corpus text, scans and line images keep CC BY-SA 4.0. Fonts keep the SIL Open Font License.
