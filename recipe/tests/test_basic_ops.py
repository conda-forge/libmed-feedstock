from med.medfile import MEDfileOpen, MED_ACC_RDONLY
from med.medmesh import MEDmeshInfo
import pathlib


def test_medfileinfo():
    fid = MEDfileOpen((pathlib.Path(__file__).parent / "files/test12.med").absolute().as_posix(), MED_ACC_RDONLY)

    # En python, il n'est pas necessaire de demander la dimension de l'espace
    # avant la demande d'information sur le maillage

    # /* Lecture des infos concernant le premier maillage */
    maa, sdim, mdim, type, desc, dtunit, sort, nstep, rep, nomcoo, unicoo = MEDmeshInfo(fid, 1)
