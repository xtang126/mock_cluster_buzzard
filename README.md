# mock_cluster_buzzard — Buzzard cluster mock with optical-selection effects

Forward model for a DES Y3-like cluster data vector built on Buzzard halos,
with the Costanzi+2026 (C26) optical-selection systematics layered on. The
notebook constructs the lensing data vector along **two parallel routes**
that live on the same DES Y1 binning, so a downstream user can compare
them directly:

- **Analytical (Matteo / C26 Eq. C1).** Bin halos on the C19 forward-model
  $(\lambda^\mathrm{ob}, z^\mathrm{ob})$ — kernel-driven, no per-halo LSS
  information — then apply the C26 Appendix C fitting function
  $\mathcal{B}^{\Delta\Sigma}_\mathrm{C1}(R)$ to the stacked $\Delta\Sigma$.
  Five constants per richness/redshift bin, no integration. Cheap enough
  for an MCMC chain.
- **Empirical (Heidi / mass-matched ratio).** Bin halos on the catalog
  redMaPPer outputs $(\mathtt{LAMBDA\_CHISQ}, \mathtt{Z\_LAMBDA})$ — these
  carry per-halo LSS information — then divide by a
  $(\log M, z_\mathrm{true})$-matched random reference (Wu+2022 method
  iii). No fitting function, both numerator and denominator come straight
  from `mock['DeltaSigma']`.

Both routes share the same C19 forward model upstream (mass–richness +
projection kernel) and the same lensing geometry $\Sigma_\mathrm{crit}^{-1}(z_l)$.

Member-galaxy contamination is injected from the published DES Y1 boost-factor
profiles in `data/boost_factor/profiles/` (McClintock+2019); the saved final
shear `gamma_t_mock_obs` mimics the raw uncorrected DES Y1 data vector.

## Outputs

Saved by the final notebook cell to `output/MockDataVector.npz`. With
$N_\lambda = 4$, $N_z = 3$, $N_R = 11$ (DES Y1 boost-factor R grid,
$0.166$ to $15.80$ Mpc):

| key                  | shape          | meaning                                                            |
|----------------------|----------------|--------------------------------------------------------------------|
| `NC`                 | $(4, 3)$       | $N(\lambda^\mathrm{ob}, z^\mathrm{ob})$, Buzzard counts rescaled by $\Omega_\mathrm{Y1}(z)$ |
| `gamma_t_stack_C19`  | $(4, 3, 11)$   | analytical: stacked $\gamma_t$, no correction                     |
| `gamma_t_obs_C1`     | $(4, 3, 11)$   | analytical: stack $\times \mathcal{B}^{\Delta\Sigma}_\mathrm{C1}$ |
| `B_sel_C1`           | $(4, 3, 11)$   | analytical: $\mathcal{B}^{\Delta\Sigma}_\mathrm{C1}(R)$           |
| `gamma_t_stack_RM`   | $(4, 3, 11)$   | empirical: $(\log M, z)$-matched random reference                 |
| `gamma_t_obs_RM`     | $(4, 3, 11)$   | empirical: redMaPPer-selected stack                               |
| `B_sel_emp`          | $(4, 3, 11)$   | empirical: bootstrap-mean $\mathcal{B}_\mathrm{sel}^\mathrm{emp}(R)$ |
| `B_data`              | $(4, 3, 11)$    | DES Y1 measured boost factor $B(R)$                              |
| `B_data_err`          | $(4, 3, 11)$    | 1-$\sigma$ error per radial bin                                  |
| `B_data_cov`          | $(4, 3, 11, 11)$| full radial covariance matrix per bin                            |
| `gamma_t_mock_obs_C1` | $(4, 3, 11)$    | analytical (Matteo) shear with Y1 boost dilution                 |
| `gamma_t_mock_obs_RM` | $(4, 3, 11)$    | empirical (Heidi) shear with Y1 boost dilution                   |

Plus bin metadata: `radii_phys_mpc`, `lambda_bins`, `z_bin_min`, `z_bin_max`.

The headline plots are also written to `output/figs/` as PNGs and embedded
in `docs/MockDataVector.pdf`.

## Binning (DES Y1)

Both number counts and the lensing data vector use the DES Y1 cluster
binning (Costanzi+2019, McClintock+2019):

- `LBDBINS   = [20, 30, 45, 60, 500]` (4 richness bins; the 500 caps
  $[60, \infty)$).
- `ZMIN_LIST = [0.20, 0.35, 0.50]`, `ZMAX_LIST = [0.35, 0.50, 0.65]`.

Halo selection mirrors `0-MakeMock.ipynb`: `pid == -1`, $0 \le \cos i \le 1$,
drop the Buzzard $0.33 \le z < 0.37$ box seam, then require
$0.20 \le z \le 0.65$ and $\log_{10} M_\mathrm{vir} \ge 13$. Yields
$\sim 5.83 \times 10^5$ halos.

## DES-Y1 NC+3×2pt mass–richness parameters

Hard-coded in `src/costanzi_selection.py`.

| Symbol     | Value             |
|------------|-------------------|
| `M_min`    | $10^{11.385}\,M_\odot$ |
| `α`        | 0.859             |
| `M_1`      | $10^{12.696}\,M_\odot$ |
| `M_pivot`  | $M_1 - M_\mathrm{min}$ |
| `σ_intr`   | 0.181             |
| `ε`        | 0.284             |
| `z_piv`    | 0.4544            |

Projection coefficients ($a_\tau, b_\tau, a_{f_\mathrm{prj}}, b_{f_\mathrm{prj}}, \dots$)
are loaded as the posterior mean of the 15 rows in
`data/prj_params_DESY3_lss_lin_dep_getdist_v1.txt` (downloaded from
`MCostanzi/SelectionBias`).

## Notebook structure

| Section | Content |
|---|---|
| §1 | Inputs (cosmology, DES Y1 binning, RNG seed) |
| §2 | Load halo catalogue + per-halo $\Sigma$, $\Delta\Sigma$ profiles; photo-$z$ proxy |
| §3 | Sample $\lambda_\mathrm{true}$ from C26 Eq. 15 |
| §4 | Project $\lambda_\mathrm{true} \to \lambda_\mathrm{obs}$ via C19 Eq. 6 mixture |
| §4.5 | Stacked $\Sigma$ in $\lambda^\mathrm{tr}$ vs $\lambda^\mathrm{ob}$ bins (mass-dilution diagnostic) |
| §5 | Output 1 — $N(\lambda_\mathrm{obs}, z_\mathrm{obs})$ |
| §5.5 | Sanity: C19 sampler $\lambda^\mathrm{ob}$ vs catalog `LAMBDA_CHISQ` |
| §6 | Halo mass function: Buzzard vs analytical Tinker08 |
| **§7** | **Lensing data vector — ANALYTICAL route (C26 Eq. C1)** |
| §7.1 | Selection-bias ratio $\mathcal{B}^{\Delta\Sigma}_\mathrm{C1}(R)$ |
| §7.2 | Tangential shear, with vs without C1 correction |
| §7.3 | Boost factor $B(R)$ from DES Y1 measurements; final mock-observed shear |
| **§8** | **Lensing data vector — EMPIRICAL route (mass-matched ratio)** |
| §8.1 | Selection-bias ratio $\mathcal{B}_\mathrm{sel}^\mathrm{emp}(R)$ with bootstrap bands; null test |
| §8.2 | Tangential shear: redMaPPer-selected vs mass-matched random |
| §9 | Save the data vector to `output/MockDataVector.npz` |

## How to run

1. Open `MockDataVector.ipynb` (at the repo root) and run top to
   bottom. The first cell adds `src/` to `sys.path` so the helper
   modules import directly. Expected wall-clock time: a few minutes
   (the §8.1 bootstrap of the mass-matched reference is the slow part).
2. Outputs land in `output/MockDataVector.npz` plus headline plots
   in `output/figs/`.

## Repository layout

```
mock_cluster_buzzard/
├── README.md
├── MockDataVector.ipynb        ← main entry, run top to bottom
├── src/                            ← Python helpers (added to sys.path by the notebook)
│   ├── costanzi_selection.py       ← C26 Eq. 15 sampler + C19 Eq. 6 mixture
│   ├── stacked_profile_weighted_by_mass_redshift.py  ← Wu+22 (M, z) match
│   ├── radial_bins_phys_mpc.py     ← rp_phys_mpc 15-bin radial grid
│   └── fileLoc.py                  ← machine-resolved paths to Buzzard inputs
├── data/
│   └── prj_params_DESY3_lss_lin_dep_getdist_v1.txt   ← C19 projection coefs
├── docs/
│   ├── MockDataVector.tex      ← technical reference
│   └── MockDataVector.pdf      ← compiled PDF (embeds vital plots)
└── output/                         ← produced by running the notebook
    ├── MockDataVector.npz
    └── figs/                       ← headline PNGs (7 figures)
```

## Files the notebook reads

External Buzzard inputs, all resolved via `FileLocs(machine='nersc')` in
`src/fileLoc.py`:

- `halo_run_fname` — raw halo catalogue (Mvir, z, RA, DEC, pid, cosi, …).
- `profile_output_fname` — per-halo $\Sigma(R)$ and $\Delta\Sigma(R)$ profiles.
- `mock_boost_factor_1d` → `beta_table_zl_y1_like.npz` ($\beta_\mathrm{eff}$,
  $z_\mathrm{lens}$ grid used to build $\Sigma_\mathrm{crit}^{-1}$).

Repo-local:

- `data/prj_params_DESY3_lss_lin_dep_getdist_v1.txt` — Costanzi posterior-sample
  table for the projection model (15 rows, 10 coefficients).
- `data/boost_factor/profiles/full-unblind-v2-mcal-zmix_y1clust_l{l}_z{z}_zpdf_boost{,_cov}.dat`
  — DES Y1 measured boost factor $B(R)$ profiles + radial covariance per
  $(\lambda, z)$ bin. Used by §7.3 of the notebook.

## Known simplifications / deferred work

- **Boost factor uses DES Y1, not Y3, measurements.** §7.3 injects
  $B(R)$ from McClintock+2019 Y1 profiles, the closest released
  measurement matching our cluster binning. A Y3 boost-factor
  measurement is not yet released; when it is, swap files in
  `data/boost_factor/profiles/`.
- Projection parameters use the **posterior mean** of the C19 chain;
  row-by-row covariance propagation is not done.
- The photo-$z$ kernel is a Gaussian $\sigma_z = 0.01\,(1+z_\mathrm{tr})$
  proxy rather than the full DES Y3 redshift-kernel of Myles+2021.
- Masking fraction $f_\mathrm{msk}$ and centering mis-identification are
  loaded but unused here.
- The §8 empirical ratio is computed on **one** Y3 realisation; Wu+2022
  Fig. 2 averages 12 Y1 + 1 Y3 realisations and is correspondingly
  tighter.

## References

- Costanzi et al. 2026, *Forward analytical model for the optical selection
  bias on galaxy cluster lensing profiles* (C26). Eqs. 15 (mass–richness),
  Appendix C Eq. C1 (selection-bias fit), Sec. III (Poisson–Gaussian
  convolution).
- Costanzi et al. 2019, arXiv:1807.07072. Eq. 6 (Gaussian + EMG mixture),
  Appendix A Eq. A8 (per-parameter forms).
- Wu et al. 2022, arXiv:2203.05416. Fig. 2 (selection-bias panel grid)
  and Appendix B (mass–redshift weighted reference).
- `MCostanzi/SelectionBias` — upstream reference notebook and the
  `prj_params_DESY3_lss_lin_dep_getdist_v1.txt` parameter file.
- `0-MakeMock.ipynb` — Buzzard halo selection recipe (mirrored).
