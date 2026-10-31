# Santali (Ol Chiki) Tesseract training

This repository holds the corpus, scripts and test images used to train `sat.traineddata`. The model is in [tessdata_contrib/sat](https://github.com/tesseract-ocr/tessdata_contrib/tree/main/sat).

## Requirements

- Tesseract 5 with the training tools (`lstmtraining`, `combine_lang_model`, `combine_tessdata`)
- Python 3 with Pillow and NumPy
- curl, to download `Latin.traineddata` from [tessdata_best](https://github.com/tesseract-ocr/tessdata_best)
- Noto Sans Ol Chiki and [Guru Gomke](https://github.com/GuruGomke) fonts

## Steps

Run each step from the repository root:

```bash
./01-prep-base.sh
python3 clean-corpus.py
python3 render-corpus.py
./02-make-lstmf.sh
python3 06-scan-to-lstmf.py <image> <gt.txt> --prefix <name>
python3 tools/augment-synthetic.py
./03-train.sh
./04-package.sh
./05-test.sh <image> <gt.txt>
```

`03-train.sh` fine-tunes from Latin. Ol Chiki is an alphabet, so Latin is a closer starting point than an abugida such as Odia.

## Contents

| Path | Purpose |
|------|---------|
| `corpus/sat_corpus.txt` | Santali source text |
| `corpus/sat_corpus2_clean.txt` | Cleaned text used for rendering |
| `clean-corpus.py` | Removes Latin letters and other non-Ol Chiki characters |
| `render-corpus.py` | Renders the corpus into line images and `gt.txt` files |
| `test-images/` | Scanned pages with ground truth |
| `tools/augment-synthetic.py` | Adds blur, noise, contrast changes and slight rotation to synthetic lines |
| `tools/benchmark.py` | Compares `sat` with the Indic OCR model on the test images |
| `tools/check-plateau.sh` | Shows when training stops improving |

## Run7 training data

The released model is Run7. It continued from the Run4 checkpoint and trained on 842 line images:

| Type | Lines |
|------|-------|
| 13 book pages: `ganam*`, `Guru*`, `AjayGada*`, `rar-sanes*`, `Sahayinon*` | 336 |
| 6 pages of the Pandit Raghunath Murmu article, printed and scanned on a flatbed: `p1` to `p6` | 166 |
| Synthetic lines in 4 font styles | 240 |
| Synthetic lines from `tools/augment-synthetic.py` | 100 |

Very short lines, such as a single danda, were removed from the `p1`, `p2`, `p5` and `p6` ground truth. The line detector does not find them.

All 19 test pages were used in training. Keep new pages out of training to measure accuracy on unseen text.

## Sources

The test images come from Santali Wikisource books under CC BY-SA 4.0. They include *ᱜᱟᱱᱟᱝ ᱟᱨ ᱪᱤᱴᱷᱤ ᱥᱟᱠᱟᱢ (Gānāṁ ār ciṭhi sākām)* (2008) by Hajam Baskey.

Corpus text, all CC BY-SA 4.0:

- Chapter 1 of [OpenSpeaks](https://en.wikiversity.org/wiki/OpenSpeaks/sat) by Subhashish Panigrahi, translated into Santali by R Ashwani Banjan Murmu, Fagu Baskey and Joy Sagar Murmu
- Santali Wikisource article on [Pandit Raghunath Murmu](https://w.wiki/D$AN)
- [Community Language Documentation & Archiving Training](https://w.wiki/ReCS), translated by Bodi Baski

## Credits

Subhashish Panigrahi trained the model. Ramjit Tudu guided the choice of Wikisource books and shared background on earlier Santali OCR work. Prasanta Hembram tested interim models and advised during training.

## Licence

Code: Apache 2.0, the same as Tesseract. Corpus text and test images keep CC BY-SA 4.0.
