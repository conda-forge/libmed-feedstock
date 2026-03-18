C     Test MED Fortran mesh operations:
C       - Mesh creation (mmhcre)
C       - Node coordinate writing (mmhcow)
C       - Element connectivity writing (mmhcyw)
C       - Mesh info read-back (mmhnmh, mmhmii)
C       - Coordinate read-back with verification (mmhcor)
C
C     These are core operations used by code-aster's mesh I/O
C
      program test_mesh

      implicit none
      include 'med.hf'

      integer*8 fid
      integer*8 cret
      integer*8 mdim, sdim, nnoe, ntet
C     MED_NO_DT/MED_NO_IT from med_parameter.hf are integer*4.
C     On Linux med_int=long (8 bytes), so we need integer*8 versions
C     to avoid sign-extension issues when passing to the C library.
      integer*8 MY_NO_DT, MY_NO_IT
      parameter (MY_NO_DT=-1, MY_NO_IT=-1)
      character*64 maa
      character*200 desc
      character*16 nomcoo(3)
      character*16 unicoo(3)
      real*8 coo(12)
      real*8 coo_read(12)
      real*8 dt
C     Element connectivity: 1 tetrahedron with 4 nodes
      integer*8 con(4)
C     Read-back variables
      integer*8 nmesh
      integer*8 type, stype, nstep, atype
      character*64 maa_read
      character*16 nomcoo_read(3)
      character*16 unicoo_read(3)
      character*200 desc_read
      character*16 dtunit_read
      integer*8 sdim_read, mdim_read
      integer*8 i

      parameter (mdim=3, sdim=3, nnoe=4, ntet=1)
      parameter (maa='test_mesh', dt=0.0d0)
      data nomcoo /'x','y','z'/, unicoo /'cm','cm','cm'/
C     4 nodes of a tetrahedron (FULL_INTERLACE: x1,y1,z1, x2,...)
      data coo /0.0d0, 0.0d0, 0.0d0,
     &          1.0d0, 0.0d0, 0.0d0,
     &          0.0d0, 1.0d0, 0.0d0,
     &          0.0d0, 0.0d0, 1.0d0/
C     Connectivity: tetrahedron using all 4 nodes
      data con /1, 2, 3, 4/

C     === WRITE PHASE ===

C     Create file
      call mfiope(fid, 'test_mesh.med', MED_ACC_RDWR, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfiope failed'
         call exit(1)
      endif

C     Create unstructured 3D mesh
      call mmhcre(fid, maa, mdim, sdim,
     &     MED_UNSTRUCTURED_MESH, 'Mesh for Fortran API test',
     &     '', MED_SORT_DTIT, MED_CARTESIAN, nomcoo, unicoo, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhcre failed'
         call exit(1)
      endif

C     Write node coordinates
      call mmhcow(fid, maa, MY_NO_DT, MY_NO_IT, dt,
     &     MED_FULL_INTERLACE, nnoe, coo, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhcow failed'
         call exit(1)
      endif

C     Write element connectivity (1 TETRA4)
      call mmhcyw(fid, maa, MY_NO_DT, MY_NO_IT, dt,
     &     MED_CELL, MED_TETRA4, MED_NODAL,
     &     MED_FULL_INTERLACE, ntet, con, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhcyw failed'
         call exit(1)
      endif

C     Close file
      call mficlo(fid, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficlo write-phase failed'
         call exit(1)
      endif

C     === READ PHASE ===

C     Re-open read-only
      call mfiope(fid, 'test_mesh.med', MED_ACC_RDONLY, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfiope reopen failed'
         call exit(1)
      endif

C     Check number of meshes
      call mmhnmh(fid, nmesh, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhnmh failed'
         call exit(1)
      endif
      if (nmesh .ne. 1) then
         print *, 'ERROR: expected 1 mesh, got', nmesh
         call exit(1)
      endif

C     Read mesh info by index
      call mmhmii(fid, 1, maa_read, sdim_read, mdim_read,
     &     type, desc_read, dtunit_read, stype, nstep, atype,
     &     nomcoo_read, unicoo_read, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhmii failed'
         call exit(1)
      endif
      if (mdim_read .ne. 3) then
         print *, 'ERROR: expected mdim=3, got', mdim_read
         call exit(1)
      endif
      if (sdim_read .ne. 3) then
         print *, 'ERROR: expected sdim=3, got', sdim_read
         call exit(1)
      endif
      print *, 'Mesh name: ', trim(maa_read)
      print *, 'Mesh dim:', mdim_read, ' Space dim:', sdim_read

C     Read coordinates back
      call mmhcor(fid, maa_read, MY_NO_DT, MY_NO_IT,
     &     MED_FULL_INTERLACE, coo_read, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhcor failed'
         call exit(1)
      endif

C     Verify coordinates match
      do i = 1, 12
         if (abs(coo_read(i) - coo(i)) .gt. 1.0d-10) then
            print *, 'ERROR: coordinate mismatch at index', i
            print *, '  expected:', coo(i), ' got:', coo_read(i)
            call exit(1)
         endif
      enddo
      print *, 'Coordinates verified OK'

C     Close file
      call mficlo(fid, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficlo final close failed'
         call exit(1)
      endif

      print *, 'test_mesh: PASSED'

      end
