package net.alexbarry.alexgames

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.NavHostFragment
import net.alexbarry.alexgames.server.GameServerService

// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Use the [ServerCreationFragment.newInstance] factory method to
 * create an instance of this fragment.
 */
class ServerCreationFragment : Fragment() {
    // TODO: Rename and change types of parameters
    private var param1: String? = null
    private var param2: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            param1 = it.getString(ARG_PARAM1)
            param2 = it.getString(ARG_PARAM2)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_server_creation, container, false)

        view.findViewById<EditText>(R.id.http_port_edit_text).hint = GameServerService.DEFAULT_HTTP_PORT.toString()
        view.findViewById<EditText>(R.id.ws_port_edit_text).hint   = GameServerService.DEFAULT_WS_PORT.toString()

        view.findViewById<Button>(R.id.btn_start_server).setOnClickListener {
            // TODO check if a server is already running, and if so, cancel it?
            var httpPort = view.findViewById<EditText>(R.id.http_port_edit_text).text.toString().toIntOrNull()
            var wsPort = view.findViewById<EditText>(R.id.ws_port_edit_text).text.toString().toIntOrNull()

            GameServerService.startService(context, httpPort, wsPort)
            val navHostFragment = NavHostFragment.findNavController(this)
            navHostFragment.navigate(R.id.action_serverCreationFragment_to_serverMonitorActivity)
        }
        return view
    }

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment ServerCreationFragment.
         */
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(param1: String, param2: String) =
            ServerCreationFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
            }
    }
}