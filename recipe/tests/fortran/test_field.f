C     Test MED Fortran field operations:
C       - Field creation (mfdcre)
C       - Real field value writing at nodes (mfdrvw)
C       - Field count and component queries (mfdnfd, mfdnfc)
C       - Real field value read-back with verification (mfdrvr)
C
C     These are core operations used by code-aster's result I/O
C     (as_mfdcre, as_mfdrpr/as_mfdrvr, etc.)
C
      program test_field

      implicit none
      include 'med.hf'

      integer*8 fid
      integer cret
      integer mdim, sdim, nnoe
      character*64 maa
      character*16 nomcoo(3)
      character*16 unicoo(3)
      real*8 coo(12)
      real*8 dt

C     Field variables
      character*64 fname
      character*16 cname(3)
      character*16 cunit(3)
      real*8 val(12)
      real*8 val_read(12)
      integer nfd, ncomp
      integer i

      parameter (mdim=3, sdim=3, nnoe=4)
      parameter (maa='field_mesh', fname='displacement')
      parameter (dt=0.0d0)
      data nomcoo /'x','y','z'/, unicoo /'cm','cm','cm'/
      data cname /'dx','dy','dz'/, cunit /'m','m','m'/
C     4 nodes in 3D (tetrahedron vertices)
      data coo /0.0d0, 0.0d0, 0.0d0,
     &          1.0d0, 0.0d0, 0.0d0,
     &          0.0d0, 1.0d0, 0.0d0,
     &          0.0d0, 0.0d0, 1.0d0/
C     Displacement field: 3 components at 4 nodes (FULL_INTERLACE)
      data val /0.1d0, 0.2d0, 0.3d0,
     &          0.4d0, 0.5d0, 0.6d0,
     &          0.7d0, 0.8d0, 0.9d0,
     &          1.0d0, 1.1d0, 1.2d0/

C     === WRITE PHASE ===

C     Create file
      call mfiope(fid, 'test_field.med', MED_ACC_RDWR, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfiope failed'
         call exit(1)
      endif

C     Create mesh (required as field support)
      call mmhcre(fid, maa, mdim, sdim,
     &     MED_UNSTRUCTURED_MESH, 'Mesh for field test',
     &     '', MED_SORT_DTIT, MED_CARTESIAN, nomcoo, unicoo, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhcre failed'
         call exit(1)
      endif

C     Write node coordinates
      call mmhcow(fid, maa, MED_NO_DT, MED_NO_IT, dt,
     &     MED_FULL_INTERLACE, nnoe, coo, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mmhcow failed'
         call exit(1)
      endif

C     Create a field (3-component real field on the mesh)
      call mfdcre(fid, fname, MED_FLOAT64, 3,
     &     cname, cunit, '', maa, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfdcre failed'
         call exit(1)
      endif

C     Write real field values at nodes
      call mfdrvw(fid, fname, MED_NO_DT, MED_NO_IT, dt,
     &     MED_NODE, MED_NONE, MED_FULL_INTERLACE,
     &     MED_ALL_CONSTITUENT, nnoe, val, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfdrvw failed'
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
      call mfiope(fid, 'test_field.med', MED_ACC_RDONLY, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfiope reopen failed'
         call exit(1)
      endif

C     Count fields in file
      call mfdnfd(fid, nfd, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfdnfd failed'
         call exit(1)
      endif
      if (nfd .ne. 1) then
         print *, 'ERROR: expected 1 field, got', nfd
         call exit(1)
      endif
      print *, 'Number of fields:', nfd

C     Query number of components in field 1
      call mfdnfc(fid, 1, ncomp, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfdnfc failed'
         call exit(1)
      endif
      if (ncomp .ne. 3) then
         print *, 'ERROR: expected 3 components, got', ncomp
         call exit(1)
      endif
      print *, 'Field components:', ncomp

C     Read real field values back
      call mfdrvr(fid, fname, MED_NO_DT, MED_NO_IT,
     &     MED_NODE, MED_NONE, MED_FULL_INTERLACE,
     &     MED_ALL_CONSTITUENT, val_read, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mfdrvr failed'
         call exit(1)
      endif

C     Verify field values
      do i = 1, 12
         if (abs(val_read(i) - val(i)) .gt. 1.0d-10) then
            print *, 'ERROR: field value mismatch at index', i
            print *, '  expected:', val(i), ' got:', val_read(i)
            call exit(1)
         endif
      enddo
      print *, 'Field values verified OK'

C     Close file
      call mficlo(fid, cret)
      if (cret .ne. 0) then
         print *, 'ERROR: mficlo final close failed'
         call exit(1)
      endif

      print *, 'test_field: PASSED'

      end
