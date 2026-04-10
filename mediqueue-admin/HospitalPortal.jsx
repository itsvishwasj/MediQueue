import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { QRCodeCanvas } from 'qrcode.react';

const HospitalPortal = () => {
  const [doctors, setDoctors] = useState([]);
  // Get ID directly from localStorage to avoid state delays
  const hospitalId = localStorage.getItem('hospitalId') || "69d20400dcc05573cc367d24";

  useEffect(() => {
    const loadData = async () => {
      try {
        const res = await axios.get(`https://mediqueue-backend-el5a.onrender.com/api/doctors?hospitalId=${hospitalId}`);

        // LOG THIS - Check your console (F12) to see if this prints
        console.log("DEMO DEBUG - API Response:", res.data);

        // FORCE PATH: Check if data is in .doctors or is the direct response
        const list = res.data.doctors || res.data.data || (Array.isArray(res.data) ? res.data : []);

        setDoctors([...list]);
      } catch (err) {
        console.error("Fetch failed", err);
      }
    };
    if (hospitalId) loadData();
  }, [hospitalId]);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Akshay Hospital Portal</h1>

      {/* STATS CARDS */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <div className="p-4 bg-blue-50 rounded-lg shadow">
          <p className="text-gray-500 text-sm">Active Doctors</p>
          <p className="text-3xl font-bold">{doctors.length}</p>
        </div>
      </div>

      {/* DOCTOR TABLE */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-gray-50">
            <tr>
              <th className="p-4">Doctor Name</th>
              <th className="p-4">Department</th>
            </tr>
          </thead>
          <tbody>
            {doctors.length > 0 ? (
              doctors.map((doc, i) => (
                <tr key={i} className="border-t">
                  <td className="p-4 font-medium">{doc.name}</td>
                  <td className="p-4 text-gray-600">{doc.department}</td>
                </tr>
              ))
            ) : (
              <tr><td colSpan="2" className="p-10 text-center text-gray-400">No doctors loaded. Refreshing...</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* QR CODE - Hardcoded fallback for the demo */}
      <div className="mt-12 p-6 bg-gray-50 rounded-xl text-center">
        <h3 className="font-bold mb-4">Reception QR Code</h3>
        <div className="inline-block p-4 bg-white rounded-lg shadow-sm">
          <QRCodeCanvas value={hospitalId} size={150} />
        </div>
        <p className="text-xs text-gray-400 mt-2">ID: {hospitalId}</p>
      </div>
    </div>
  );
};

export default HospitalPortal;
